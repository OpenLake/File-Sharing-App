package main

import (
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"time"

	"github.com/joho/godotenv"
	"github.com/minio/minio-go"
)

var filename = " "

func main() {
	http.HandleFunc("/upload", uploadFile)
	http.HandleFunc("/download", downloadFile)
	http.ListenAndServe(":8000", nil)
}

func uploadFile(w http.ResponseWriter, r *http.Request) {
	// Parse the form data
	r.ParseMultipartForm(32 << 20)
	fmt.Println(r.ContentLength)
	// Get the file from the form data
	file, h, err := r.FormFile("file")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	fmt.Println(h.Header)
	fmt.Println(h.Size)
	fmt.Println(h.Filename)

	filename = h.Filename
	defer file.Close()
	godotenv.Load(".env")
	// ctx := context.Background()
	endpoint := os.Getenv("LOCAL_IP")
	fmt.Println(endpoint)
	accessKeyID := os.Getenv("ACCESS_KEY")
	secretAccessKey := os.Getenv("SECRET_KEY")
	useSSL := false

	// Create a Minio client
	minioClient, err := minio.New(endpoint, accessKeyID, secretAccessKey, useSSL)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		fmt.Println(err)
		return

	}

	// Upload the file to Minio
	_, err = minioClient.PutObject("sarvesh", filename, file, -1, minio.PutObjectOptions{ContentType: "application/octet-stream"})
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		fmt.Println(err)
		return
	}
	// Set request parameters for content-disposition.
	reqParams := make(url.Values)
	reqParams.Set("response-content-disposition", "attachment; filename=\"your-filename.pdf\"")
	// Generates a presigned url which expires in a day.
	presignedURL, err := minioClient.PresignedGetObject("sarvesh", filename, time.Second*24*60*60, reqParams)
	if err != nil {
		fmt.Println(err)
		return
	}
	fmt.Println(presignedURL)
	_, err = io.WriteString(w, presignedURL.String())
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	fmt.Fprintf(w, "File uploaded successfully")
}

func downloadFile(w http.ResponseWriter, r *http.Request) {
	godotenv.Load(".env")
	endpoint := os.Getenv("LOCAL_IP")
	accessKeyID := os.Getenv("ACCESS_KEY")
	secretAccessKey := os.Getenv("SECRET_KEY")
	useSSL := false
	// Create a Minio client
	minioClient, err := minio.New(endpoint, accessKeyID, secretAccessKey, useSSL)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	reqParams := make(url.Values)
	reqParams.Set("response-content-disposition", "attachment; filename=\"your-filename.pdf\"")
	// Generates a presigned url which expires in a day.
	presignedURL, err := minioClient.PresignedGetObject("sarvesh", filename, time.Second*24*60*60, reqParams)
	if err != nil {
		fmt.Println(err)
		return
	}
	fmt.Println(presignedURL)
	_, err = io.WriteString(w, presignedURL.String())
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}
