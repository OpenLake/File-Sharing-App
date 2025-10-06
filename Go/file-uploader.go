package main

import (
	"bytes"
	"context"
	"encoding/json"
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

// EncryptionMetadata stores information about encrypted files
type EncryptionMetadata struct {
	Version          string `json:"version"`
	Algorithm        string `json:"algorithm"`
	IV               string `json:"iv"`
	Key              string `json:"key"`
	OriginalFilename string `json:"originalFilename"`
	FileHash         string `json:"fileHash"`
	OriginalSize     int    `json:"originalSize"`
	Timestamp        string `json:"timestamp"`
}

func main() {
	if err := godotenv.Load(); err != nil {
		fmt.Printf("Error loading .env file: %v\n", err)
	}
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		fmt.Fprint(w, "OK")
	})
	http.HandleFunc("/upload", uploadFile)
	http.HandleFunc("/download", downloadFile)
	http.HandleFunc("/metadata", getMetadata)

	port := os.Getenv("PORT")
	if port == "" {
		port = ":8000"
	}
	if port[0] != ':' {
		port = ":" + port
	}

	fmt.Printf("Server starting on %s\n", port)
	if err := http.ListenAndServe(port, nil); err != nil {
		fmt.Printf("Server failed to start: %v\n", err)
		os.Exit(1)
	}
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

	// Parse form data
	if err := r.ParseMultipartForm(32 << 20); err != nil {
		fmt.Printf("Failed to parse form: %v\n", err)
		http.Error(w, fmt.Sprintf("Failed to parse form: %v", err), http.StatusBadRequest)
		return
	}

	// Get file
	file, h, err := r.FormFile("file")
	if err != nil {
		fmt.Printf("Failed to get file: %v\n", err)
		http.Error(w, fmt.Sprintf("Failed to get file: %v", err), http.StatusBadRequest)
		return
	}
	defer file.Close()

	// Validate file size (max 1GB)
	const maxFileSize = int64(1 << 30) // 1 GB
	if err := validateFileSize(file, maxFileSize); err != nil {
		fmt.Printf("Received file size exceeds limit of %d bytes\n", maxFileSize)
		http.Error(w, fmt.Sprintf("Received file size exceeds limit of %d bytes", maxFileSize), http.StatusBadRequest)
		return
	}

	// Validate file extension
	if err := validateFileExtension(h.Filename); err != nil {
		fmt.Printf("Recieved file %s not allowed", h.Filename)
		http.Error(w, fmt.Sprintf("Recieved file %s not allowed", h.Filename), http.StatusBadRequest)
		return
	}

	// Get encryption metadata if provided
	metadataStr := r.FormValue("metadata")
	var metadata EncryptionMetadata
	if metadataStr != "" {
		if err := json.Unmarshal([]byte(metadataStr), &metadata); err != nil {
			fmt.Printf("Failed to parse metadata: %v\n", err)
			http.Error(w, fmt.Sprintf("Failed to parse metadata: %v", err), http.StatusBadRequest)
			return
		}
		fmt.Printf("Received encrypted file: %s (original: %s), Size: %d\n",
			h.Filename, metadata.OriginalFilename, h.Size)
	} else {
		fmt.Printf("Received file: %s, Size: %d\n", h.Filename, h.Size)
	}

	// Environment variables
	endpoint := os.Getenv("LOCAL_IP")
	accessKeyID := os.Getenv("ACCESS_KEY")
	secretAccessKey := os.Getenv("SECRET_KEY")
	if endpoint == "" || accessKeyID == "" || secretAccessKey == "" {
		fmt.Println("Missing environment variables")
		http.Error(w, "Server configuration error", http.StatusInternalServerError)
		return
	}

	// Create MinIO client
	minioClient, err := minio.New(endpoint, &minio.Options{
		Creds:        credentials.NewStaticV4(accessKeyID, secretAccessKey, ""),
		Secure:       false,
		BucketLookup: minio.BucketLookupPath,
	})
	if err != nil {
		fmt.Printf("Failed to create MinIO client: %v\n", err)
		http.Error(w, fmt.Sprintf("Failed to create MinIO client: %v", err), http.StatusInternalServerError)
		return
	}

	ctx := context.Background()

	// Check and create bucket
	exists, err := minioClient.BucketExists(ctx, "sarvesh")
	if err != nil {
		fmt.Printf("Failed to check bucket: %v\n", err)
		http.Error(w, fmt.Sprintf("Failed to check bucket: %v", err), http.StatusInternalServerError)
		return
	}
	if !exists {
		err = minioClient.MakeBucket(ctx, "sarvesh", minio.MakeBucketOptions{Region: ""})
		if err != nil {
			fmt.Printf("Failed to create bucket: %v\n", err)
			http.Error(w, fmt.Sprintf("Failed to create bucket: %v", err), http.StatusInternalServerError)
			return
		}
		fmt.Println("Bucket 'sarvesh' created successfully")
	} else {
		fmt.Println("Bucket 'sarvesh' already exists")
	}

	// Upload to MinIO
	uploadInfo, err := minioClient.PutObject(ctx, "sarvesh", h.Filename, file, h.Size, minio.PutObjectOptions{
		ContentType: "application/octet-stream",
	})
	if err != nil {
		fmt.Printf("Failed to upload file to MinIO: %v\n", err)
		http.Error(w, fmt.Sprintf("Failed to upload file to MinIO: %v", err), http.StatusInternalServerError)
		return
	}
	fmt.Printf("File uploaded to MinIO: %s (size: %d)\n", h.Filename, uploadInfo.Size)

	// If metadata exists, store it separately
	if metadataStr != "" {
		metadataFilename := h.Filename + ".metadata.json"
		metadataReader := io.NopCloser(bytes.NewReader([]byte(metadataStr)))
		_, err = minioClient.PutObject(ctx, "sarvesh", metadataFilename, metadataReader,
			int64(len(metadataStr)), minio.PutObjectOptions{
				ContentType: "application/json",
			})
		if err != nil {
			fmt.Printf("Warning: Failed to upload metadata: %v\n", err)
			// Continue even if metadata upload fails
		} else {
			fmt.Printf("Metadata uploaded: %s\n", metadataFilename)
		}
	}

	// Generate presigned URL
	reqParams := make(url.Values)
	reqParams.Set("response-content-disposition", fmt.Sprintf("attachment; filename=%q", h.Filename))
	presignedURL, err := minioClient.PresignedGetObject(ctx, "sarvesh", h.Filename, time.Second*24*60*60, reqParams)
	if err != nil {
		fmt.Printf("Failed to generate presigned URL: %v\n", err)
		http.Error(w, fmt.Sprintf("Failed to generate presigned URL: %v", err), http.StatusInternalServerError)
		return
	}

	// Write response
	if _, err := io.WriteString(w, presignedURL.String()); err != nil {
		fmt.Printf("Failed to write response: %v\n", err)
		http.Error(w, fmt.Sprintf("Failed to write response: %v", err), http.StatusInternalServerError)
		return
	}
	fmt.Fprintf(w, "\nFile uploaded successfully")
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

	// Load environment variables
	endpoint := os.Getenv("LOCAL_IP")
	accessKeyID := os.Getenv("ACCESS_KEY")
	secretAccessKey := os.Getenv("SECRET_KEY")
	if endpoint == "" || accessKeyID == "" || secretAccessKey == "" {
		http.Error(w, "Server configuration error", http.StatusInternalServerError)
		return
	}

	// Create a MinIO client
	minioClient, err := minio.New(endpoint, &minio.Options{
		Creds:        credentials.NewStaticV4(accessKeyID, secretAccessKey, ""),
		Secure:       false,
		BucketLookup: minio.BucketLookupPath,
	})
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to create MinIO client: %v", err), http.StatusInternalServerError)
		return
	}

	// Create context
	ctx := context.Background()

	// Generate presigned URL
	reqParams := make(url.Values)
	reqParams.Set("response-content-disposition", fmt.Sprintf("attachment; filename=%q", filename))
	presignedURL, err := minioClient.PresignedGetObject(ctx, "sarvesh", filename, time.Second*24*60*60, reqParams)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to generate presigned URL: %v", err), http.StatusInternalServerError)
		return
	}

	// Write presigned URL to response
	if _, err := io.WriteString(w, presignedURL.String()); err != nil {
		http.Error(w, fmt.Sprintf("Failed to write response: %v", err), http.StatusInternalServerError)
		return
	}
}

func getMetadata(w http.ResponseWriter, r *http.Request) {
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

	// Load environment variables
	endpoint := os.Getenv("LOCAL_IP")
	accessKeyID := os.Getenv("ACCESS_KEY")
	secretAccessKey := os.Getenv("SECRET_KEY")
	if endpoint == "" || accessKeyID == "" || secretAccessKey == "" {
		http.Error(w, "Server configuration error", http.StatusInternalServerError)
		return
	}

	// Create a MinIO client
	minioClient, err := minio.New(endpoint, &minio.Options{
		Creds:        credentials.NewStaticV4(accessKeyID, secretAccessKey, ""),
		Secure:       false,
		BucketLookup: minio.BucketLookupPath,
	})
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to create MinIO client: %v", err), http.StatusInternalServerError)
		return
	}

	// Create context
	ctx := context.Background()

	// Get metadata file
	metadataFilename := filename + ".metadata.json"
	object, err := minioClient.GetObject(ctx, "sarvesh", metadataFilename, minio.GetObjectOptions{})
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to get metadata: %v", err), http.StatusNotFound)
		return
	}
	defer object.Close()

	// Read metadata content
	buf := new(bytes.Buffer)
	if _, err := buf.ReadFrom(object); err != nil {
		http.Error(w, fmt.Sprintf("Failed to read metadata: %v", err), http.StatusInternalServerError)
		return
	}

	// Set content type and write response
	w.Header().Set("Content-Type", "application/json")
	if _, err := w.Write(buf.Bytes()); err != nil {
		http.Error(w, fmt.Sprintf("Failed to write response: %v", err), http.StatusInternalServerError)
		return
	}
}

// Checks if the file extension is allowed
func validateFileExtension(filename string) error {
	ext := strings.ToLower(filepath.Ext(filename))
	if ext == "" {
		return fmt.Errorf("file extension not found")
	}

	allowedFileTypes := map[string]bool{
		".jpg":  true,
		".jpeg": true,
		".png":  true,
		".gif":  true,
		".pdf":  true,
		".txt":  true,
		".doc":  true,
		".docx": true,
		".zip":  true,
	}

	if !allowedFileTypes[ext] {
		return fmt.Errorf("file: %s with type %s not allowed", filename, ext)
	}

	return nil
}

// Checks if the file size exceeds the maximum allowed size
func validateFileSize(file multipart.File, maxFileSize int64) error {
	var size int64
	limitedReader := io.LimitReader(file, maxFileSize+1)
	buf := make([]byte, 32*1024)
	for {
		n, err := limitedReader.Read(buf)
		size += int64(n)
		if err == io.EOF {
			break
		}
		if err != nil {
			return fmt.Errorf("error reading file: %v", err)
		}
		if size > maxFileSize {
			return fmt.Errorf("file size exceeds limit of %d bytes", maxFileSize)
		}
	}

	// Reset file reader to start
	file.Seek(0, io.SeekStart)

	return nil
}
