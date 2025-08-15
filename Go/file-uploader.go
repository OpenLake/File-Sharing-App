package main

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"time"

	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
)

func main() {
	http.HandleFunc("/upload", uploadFile)
	http.HandleFunc("/download", downloadFile)
	fmt.Println("Server starting on :8000")
	if err := http.ListenAndServe(":8000", nil); err != nil {
		fmt.Printf("Server failed to start: %v\n", err)
		os.Exit(1)
	}
}

func uploadFile(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Parse the form data
	if err := r.ParseMultipartForm(32 << 20); err != nil {
		http.Error(w, fmt.Sprintf("Failed to parse form: %v", err), http.StatusBadRequest)
		return
	}

	// Get the file from the form data
	file, h, err := r.FormFile("file")
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to get file: %v", err), http.StatusBadRequest)
		return
	}
	defer file.Close()

	fmt.Printf("Uploaded file: %s, Size: %d\n", h.Filename, h.Size)

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
		Creds:  credentials.NewStaticV4(accessKeyID, secretAccessKey, ""),
		Secure: false,
	})
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to create MinIO client: %v", err), http.StatusInternalServerError)
		return
	}

	// Create context
	ctx := context.Background()

	// Upload the file to MinIO
	_, err = minioClient.PutObject(ctx, "sarvesh", h.Filename, file, h.Size, minio.PutObjectOptions{
		ContentType: "application/octet-stream",
	})
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to upload file to MinIO: %v", err), http.StatusInternalServerError)
		return
	}

	// Generate presigned URL
	reqParams := make(url.Values)
	reqParams.Set("response-content-disposition", fmt.Sprintf("attachment; filename=%q", h.Filename))
	presignedURL, err := minioClient.PresignedGetObject(ctx, "sarvesh", h.Filename, time.Second*24*60*60, reqParams)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to generate presigned URL: %v", err), http.StatusInternalServerError)
		return
	}

	// Write presigned URL to response
	if _, err := io.WriteString(w, presignedURL.String()); err != nil {
		http.Error(w, fmt.Sprintf("Failed to write response: %v", err), http.StatusInternalServerError)
		return
	}

	fmt.Fprintf(w, "\nFile uploaded successfully")
}

func downloadFile(w http.ResponseWriter, r *http.Request) {
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
		Creds:  credentials.NewStaticV4(accessKeyID, secretAccessKey, ""),
		Secure: false,
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
