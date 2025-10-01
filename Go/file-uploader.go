package main

import (
	"context"
	"errors"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/joho/godotenv"
	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
)

// MinIO configuration
type minioConfig struct {
	endpoint        string
	accessKeyID     string
	secretAccessKey string
}

const (
	defaultBucket  = "sarvesh"
	maxUploadSize  = 32 << 20 // 32 MiB
	presignExpires = 24 * time.Hour
)

// getMinioConfig loads MinIO configuration from environment
func getMinioConfig() (*minioConfig, error) {
	endpoint := os.Getenv("LOCAL_IP")
	accessKeyID := os.Getenv("ACCESS_KEY")
	secretAccessKey := os.Getenv("SECRET_KEY")

	if endpoint == "" || accessKeyID == "" || secretAccessKey == "" {
		return nil, fmt.Errorf("missing environment variables")
	}

	return &minioConfig{
		endpoint:        endpoint,
		accessKeyID:     accessKeyID,
		secretAccessKey: secretAccessKey,
	}, nil
}

// createMinioClient creates and returns a MinIO client
func createMinioClient(cfg *minioConfig) (*minio.Client, error) {
	return minio.New(cfg.endpoint, &minio.Options{
		Creds:  credentials.NewStaticV4(cfg.accessKeyID, cfg.secretAccessKey, ""),
		Secure: false,
	})
}

// ensureBucket checks if bucket exists and creates it if needed
func ensureBucket(ctx context.Context, client *minio.Client, bucketName string) error {
	exists, err := client.BucketExists(ctx, bucketName)
	if err != nil {
		return fmt.Errorf("failed to check bucket: %w", err)
	}

	if !exists {
		err = client.MakeBucket(ctx, bucketName, minio.MakeBucketOptions{Region: ""})
		if err != nil {
			return fmt.Errorf("failed to create bucket: %w", err)
		}
		fmt.Printf("Bucket '%s' created successfully\n", bucketName)
	} else {
		fmt.Printf("Bucket '%s' already exists\n", bucketName)
	}

	return nil
}

func main() {
	if err := godotenv.Load(); err != nil {
		fmt.Printf("(warn) unable to load .env file: %v\n", err)
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		fmt.Fprint(w, "OK")
	})
	mux.HandleFunc("/upload", uploadFile)
	mux.HandleFunc("/download", downloadFile)

	if err := startServer(mux); err != nil {
		fmt.Printf("Server failed to start: %v\n", err)
		os.Exit(1)
	}
}

// startServer starts the HTTP server with optional TLS + sensible timeouts
func startServer(handler http.Handler) error {
	port := getEnv("PORT", ":8000")
	useTLS := strings.EqualFold(os.Getenv("USE_TLS"), "true")
	certFile := os.Getenv("TLS_CERT_FILE")
	keyFile := os.Getenv("TLS_KEY_FILE")

	srv := &http.Server{
		Addr:              port,
		Handler:           handler,
		ReadHeaderTimeout: 10 * time.Second,
		ReadTimeout:       30 * time.Second,
		WriteTimeout:      120 * time.Second,
		IdleTimeout:       120 * time.Second,
		MaxHeaderBytes:    1 << 20, // 1MB
	}

	if useTLS {
		if certFile == "" || keyFile == "" {
			return errors.New("USE_TLS=true but TLS_CERT_FILE or TLS_KEY_FILE not set")
		}
		fmt.Printf("Server starting on %s with TLS enabled\n", port)
		return srv.ListenAndServeTLS(certFile, keyFile)
	}
	fmt.Printf("Server starting on %s over HTTP (enable TLS in production: set USE_TLS=true)\n", port)
	return srv.ListenAndServe()
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		if !strings.HasPrefix(v, ":") && strings.HasPrefix(fallback, ":") {
			return ":" + v
		}
		return v
	}
	return fallback
}

func uploadFile(w http.ResponseWriter, r *http.Request) {
	// CORS headers
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusOK)
		return
	}

	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Enforce maximum request body size early (slightly above declared limit for form overhead)
	r.Body = http.MaxBytesReader(w, r.Body, maxUploadSize+1<<20)

	// Parse and get file from request
	file, header, err := parseUploadRequest(r)
	if err != nil {
		fmt.Printf("Failed to parse request: %v\n", err)
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	defer file.Close()

	// Basic filename sanitization (strip paths, disallow traversal)
	header.Filename = sanitizeFilename(header.Filename)

	if header.Size > maxUploadSize {
		http.Error(w, fmt.Sprintf("file too large: %d bytes (limit %d)", header.Size, maxUploadSize), http.StatusRequestEntityTooLarge)
		return
	}

	fmt.Printf("Received file: %s, Size: %d bytes\n", header.Filename, header.Size)

	// Handle file upload to MinIO
	if err := handleFileUpload(w, file, header); err != nil {
		fmt.Printf("Upload failed: %v\n", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}

// parseUploadRequest parses multipart form and extracts file

func parseUploadRequest(r *http.Request) (multipart.File, *multipart.FileHeader, error) {
	if err := r.ParseMultipartForm(maxUploadSize); err != nil {
		return nil, nil, fmt.Errorf("failed to parse form: %w", err)
	}

	file, header, err := r.FormFile("file")
	if err != nil {
		return nil, nil, fmt.Errorf("failed to get file: %w", err)
	}

	// Ensure file is seekable
	if seeker, ok := file.(io.Seeker); ok {
		if _, err := seeker.Seek(0, io.SeekStart); err != nil {
			file.Close()
			return nil, nil, fmt.Errorf("failed to seek file: %w", err)
		}
	}

	return file, header, nil
}

// handleFileUpload manages the complete file upload workflow
func handleFileUpload(w http.ResponseWriter, file io.Reader, header *multipart.FileHeader) error {
	// Get MinIO configuration
	cfg, err := getMinioConfig()
	if err != nil {
		return fmt.Errorf("configuration error: %w", err)
	}
	fmt.Printf("MinIO Config - Endpoint: %s, AccessKey: %s\n", cfg.endpoint, cfg.accessKeyID)

	// Create MinIO client
	minioClient, err := createMinioClient(cfg)
	if err != nil {
		return fmt.Errorf("failed to create MinIO client: %w", err)
	}

	ctx := context.Background()
	bucketName := defaultBucket

	// Ensure bucket exists
	if err := ensureBucket(ctx, minioClient, bucketName); err != nil {
		return err
	}

	// Upload to MinIO
	uploadInfo, err := minioClient.PutObject(ctx, bucketName, header.Filename, file, header.Size, minio.PutObjectOptions{
		ContentType: "application/octet-stream",
	})
	if err != nil {
		return fmt.Errorf("failed to upload to MinIO: %w", err)
	}
	fmt.Printf("File uploaded to MinIO: %s (size: %d)\n", header.Filename, uploadInfo.Size)

	// Generate and return presigned URL
	return generateAndWriteURL(w, minioClient, bucketName, header.Filename)
}

// generateAndWriteURL creates a presigned URL and writes it to response
func generateAndWriteURL(w http.ResponseWriter, client *minio.Client, bucket, filename string) error {
	ctx := context.Background()
	reqParams := make(url.Values)
	reqParams.Set("response-content-disposition", fmt.Sprintf("attachment; filename=%q", filename))

	presignedURL, err := client.PresignedGetObject(ctx, bucket, filename, presignExpires, reqParams)
	if err != nil {
		return fmt.Errorf("failed to generate presigned URL: %w", err)
	}

	if _, err := io.WriteString(w, presignedURL.String()); err != nil {
		return fmt.Errorf("failed to write response: %w", err)
	}

	fmt.Fprintf(w, "\nFile uploaded successfully")
	return nil
}

func downloadFile(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusOK)
		return
	}

	// Get filename from query parameter
	filename := r.URL.Query().Get("filename")
	if filename == "" {
		http.Error(w, "Filename is required", http.StatusBadRequest)
		return
	}

	// Get MinIO configuration
	cfg, err := getMinioConfig()
	if err != nil {
		http.Error(w, "Server configuration error", http.StatusInternalServerError)
		return
	}

	// Create MinIO client
	minioClient, err := createMinioClient(cfg)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to create MinIO client: %v", err), http.StatusInternalServerError)
		return
	}

	// Generate and write presigned URL
	if err := generateAndWriteURL(w, minioClient, defaultBucket, filename); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}

// sanitizeFilename ensures the uploaded filename is safe and doesn't contain path traversal.
func sanitizeFilename(name string) string {
	name = filepath.Base(strings.TrimSpace(name))
	if name == "." || name == "" {
		return fmt.Sprintf("upload-%d.bin", time.Now().UnixNano())
	}
	// rudimentary blacklist of dangerous characters
	replacer := strings.NewReplacer("..", "_", "/", "_", "\\", "_", "`", "_", "|", "_", ">", "_", "<", "_", ":", "_", "\"", "_")
	cleaned := replacer.Replace(name)
	if len(cleaned) > 255 {
		cleaned = cleaned[:255]
	}
	return cleaned
}
