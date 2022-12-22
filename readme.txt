go get github.com/minio/minio-go/v7
go run file-uploader.go

to run the server use a separate terminal:-
mkdir ~/minio
minio server ~/minio --console-address :9090
