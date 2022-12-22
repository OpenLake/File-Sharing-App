package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"time"

	"github.com/gorilla/mux"
	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
)

const port = ":5500"

func main() {

	router := mux.NewRouter()
	router.HandleFunc("/", rootPage).Methods("POST")
	router.HandleFunc("/", rootPage).Methods("GET")
	fmt.Println("Serving @ http://127.0.0.1" + port)
	log.Fatal(http.ListenAndServe(port, router))
}
func rootPage(w http.ResponseWriter, r *http.Request) {
	ctx := context.Background()
	endpoint := "192.168.87.169:9000"
	accessKeyID := "WRkXVNHWZLEbsTkN"
	secretAccessKey := "sx793y7hfUYqUaNPOEjXHh9ezqgnvPib"
	useSSL := false

	// Initialize minio client object.
	minioClient, err := minio.New(endpoint, &minio.Options{
		Creds:  credentials.NewStaticV4(accessKeyID, secretAccessKey, ""),
		Secure: useSSL,
	})
	if err != nil {
		log.Fatalln(err)
	}

	// Make a new bucket called mymusic.
	bucketName := r.Header.Get("Grant_Type")
	location := "us-east-1"

	err = minioClient.MakeBucket(ctx, bucketName, minio.MakeBucketOptions{Region: location})
	if err != nil {
		// Check to see if we already own this bucket (which happens if you run this twice)
		exists, errBucketExists := minioClient.BucketExists(ctx, bucketName)
		if errBucketExists == nil && exists {
			log.Printf("We already own %s\n", bucketName)
		} else {
			log.Fatalln(err)
		}
	} else {
		log.Printf("Successfully created %s\n", bucketName)
	}

	// Upload the zip file
	objectName := "go.pdf"
	filePath := "go.pdf"
	contentType := "application/pdf"

	// Upload the zip file with FPutObject
	info, err := minioClient.FPutObject(ctx, bucketName, objectName, filePath, minio.PutObjectOptions{ContentType: contentType})
	if err != nil {
		log.Fatalln(err)
	}
	objectCh := minioClient.ListObjects(ctx, bucketName, minio.ListObjectsOptions{
		Recursive: true,
	})
	for object := range objectCh {
		if object.Err != nil {
			fmt.Println(object.Err)
			return
		}
		fmt.Println(object.Key)
	}
	// Set request parameters for content-disposition.
	reqParams := make(url.Values)
	reqParams.Set("response-content-disposition", "attachment; filename=\"your-filename.pdf\"")

	// Generates a presigned url which expires in a day.
	presignedURL, err := minioClient.PresignedGetObject(ctx, bucketName, objectName, time.Second*24*60*60, reqParams)
	if err != nil {
		fmt.Println(err)
		return
	}

	x := presignedURL.String()
	w.Write([]byte(x))
	fmt.Println("Successfully generated presigned URL", presignedURL)
	log.Printf("Successfully uploaded %s of size %d\n", objectName, info.Size)
	http.Handle("/", http.FileServer(http.Dir("./static")))
	http.ListenAndServe(":3000", nil)
}
