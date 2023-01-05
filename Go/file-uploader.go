// package main

// import (
// 	"context"
// 	"fmt"
// 	"log"
// 	"net/http"
// 	"net/url"
// 	"os"
// 	"time"

// 	"github.com/gorilla/mux"
// 	"github.com/joho/godotenv"
// 	"github.com/minio/minio-go/v7"
// 	"github.com/minio/minio-go/v7/pkg/credentials"
// )

// const port = ":5500"

// func main() {

// 	router := mux.NewRouter()
// 	router.HandleFunc("/", rootPage).Methods("POST")
// 	router.HandleFunc("/", rootPage).Methods("GET")
// 	fmt.Println("Serving @ http://127.0.0.1" + port)
// 	log.Fatal(http.ListenAndServe(port, router))
// }
// func rootPage(w http.ResponseWriter, r *http.Request) {
// 	err := godotenv.Load()
// 	if err != nil {
// 		log.Fatal("Error loading .env file")
// 	}
// 	ctx := context.Background()
// 	endpoint := os.Getenv("LOCAL_IP")
// 	accessKeyID := os.Getenv("ACCESS_KEY")
// 	secretAccessKey := os.Getenv("SECRET_KEY")
// 	useSSL := false

// 	// Initialize minio client object.
// 	minioClient, err := minio.New(endpoint, &minio.Options{
// 		Creds:  credentials.NewStaticV4(accessKeyID, secretAccessKey, ""),
// 		Secure: useSSL,
// 	})
// 	if err != nil {
// 		log.Fatalln(err)
// 	}

// 	// Make a new bucket called mymusic.
// 	bucketName := r.Header.Get("Grant_Type")
// 	location := "us-east-1"

// 	err = minioClient.MakeBucket(ctx, bucketName, minio.MakeBucketOptions{Region: location})
// 	if err != nil {
// 		// Check to see if we already own this bucket (which happens if you run this twice)
// 		exists, errBucketExists := minioClient.BucketExists(ctx, bucketName)
// 		if errBucketExists == nil && exists {
// 			log.Printf("We already own %s\n", bucketName)
// 		} else {
// 			log.Fatalln(err)
// 		}
// 	} else {
// 		log.Printf("Successfully created %s\n", bucketName)
// 	}

// 	// Upload the zip file
// 	objectName := "go.pdf"
// 	filePath := "go.pdf"
// 	contentType := "application/pdf"

// 	// Upload the zip file with FPutObject
// 	info, err := minioClient.FPutObject(ctx, bucketName, objectName, filePath, minio.PutObjectOptions{ContentType: contentType})
// 	if err != nil {
// 		log.Fatalln(err)
// 	}
// 	objectCh := minioClient.ListObjects(ctx, bucketName, minio.ListObjectsOptions{
// 		Recursive: true,
// 	})
// 	for object := range objectCh {
// 		if object.Err != nil {
// 			fmt.Println(object.Err)
// 			return
// 		}
// 		fmt.Println(object.Key)
// 	}
// 	// Set request parameters for content-disposition.
// 	reqParams := make(url.Values)
// 	reqParams.Set("response-content-disposition", "attachment; filename=\"your-filename.pdf\"")

// 	// Generates a presigned url which expires in a day.
// 	presignedURL, err := minioClient.PresignedGetObject(ctx, bucketName, objectName, time.Second*24*60*60, reqParams)
// 	if err != nil {
// 		fmt.Println(err)
// 		return
// 	}

// 	x := presignedURL.String()
// 	w.Write([]byte(x))
// 	fmt.Println("Successfully generated presigned URL", presignedURL)
// 	log.Printf("Successfully uploaded %s of size %d\n", objectName, info.Size)
// 	http.Handle("/", http.FileServer(http.Dir("./static")))
// 	http.ListenAndServe(":3000", nil)
// }
// package main

// import (
// 	"bytes"
// 	"fmt"
// 	"io/ioutil"
// 	"log"
// 	"net/http"
// 	"os"
// 	"time"

// 	"github.com/minio/minio-go/v6"
// )

// func main() {
// 	http.HandleFunc("/upload", uploadHandler)
// 	log.Fatal(http.ListenAndServe(":8080", nil))
// }

// func uploadHandler(w http.ResponseWriter, r *http.Request) {
// 	// Read file from request body
// 	fileBytes, err := ioutil.ReadAll(r.Body)
// 	if err != nil {
// 		http.Error(w, err.Error(), http.StatusInternalServerError)
// 		return
// 	}
// 	endpoint := os.Getenv("LOCAL_IP")
// 	accessKeyID := os.Getenv("ACCESS_KEY")
// 	secretAccessKey := os.Getenv("SECRET_KEY")
// 	useSSL := false
// 	// Set up Minio client
// 	minioClient, err := minio.New(endpoint, accessKeyID, secretAccessKey, useSSL)
// 	if err != nil {
// 		http.Error(w, err.Error(), http.StatusInternalServerError)
// 		return
// 	}

// 	// Generate unique file name
// 	fileName := fmt.Sprintf("%d.bin", time.Now().UnixNano())

// 	// Upload file to Minio
// 	_, err = minioClient.PutObject("my-bucket", fileName, bytes.NewReader(fileBytes), int64(len(fileBytes)), minio.PutObjectOptions{ContentType: "application/octet-stream"})
// 	if err != nil {
// 		http.Error(w, err.Error(), http.StatusInternalServerError)
// 		return
// 	}

// 	// Generate temporary download URL
// 	url, err := minioClient.PresignedGetObject("my-bucket", fileName, time.Hour, nil)
// 	if err != nil {
// 		http.Error(w, err.Error(), http.StatusInternalServerError)
// 		return
// 	}

// 	// Write download URL to response body
// 	_, err = w.Write([]byte(url.String()))
// 	if err != nil {
// 		http.Error(w, err.Error(), http.StatusInternalServerError)
// 		return
// 	}
// }
package main

import (
	"fmt"
	"io"
	"net/http"
	"os"

	"github.com/minio/minio-go"
)

func main() {
	http.HandleFunc("/upload", uploadFile)
	http.HandleFunc("/download", downloadFile)
	http.ListenAndServe(":8000", nil)
}

func uploadFile(w http.ResponseWriter, r *http.Request) {
	// Parse the form data
	r.ParseMultipartForm(32 << 20)

	// Get the file from the form data
	file, _, err := r.FormFile("file")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer file.Close()
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

	// Upload the file to Minio
	_, err = minioClient.PutObject("my-bucket", "filename", file, -1, minio.PutObjectOptions{ContentType: "application/octet-stream"})
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	fmt.Fprintf(w, "File uploaded successfully")
}

func downloadFile(w http.ResponseWriter, r *http.Request) {
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

	// Download the file from Minio
	object, err := minioClient.GetObject("my-bucket", "filename", minio.GetObjectOptions{})
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer object.Close()

	// Write the object to the response
	_, err = io.Copy(w, object)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}
