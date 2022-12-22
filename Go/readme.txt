go get github.com/minio/minio-go/v7
go run file-uploader.go
mkdir ~/minio
minio server ~/minio --console-address :9090
