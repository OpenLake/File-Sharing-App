<h1 align="center">Welcome to the File Sharing Application👋</h1>


## 🤔 Problem
We often have to transfer files between our mobile and desktop devices. But generally we do it with WhatsApp, Telegram or some other application which passes through the internet. We can create a mobile-app for use on our institutes intranet.

## ✨ Features
- Cross platform application to share go get github.com/minio/minio-go/v7 //If your go file is showing error that you dont have minio package then run this command.files between devices across an intranet. 
- Use of object storage server to share files.
- Tech Stack : Flutter, GoLang , Minio

## 📄 Running Server of Minio

**1.** Run the server of Minio in a terminal in your home directory.

**2.** Make a minio directory.
```
mkdir ~/minio
```

**3.** Run the server of Minio in a terminal with port 9090
```
minio server ~/minio --console-address :9090
```
## 📄 Running the backend (Go)


**1.** cd to Go folder and run the backend in a separate terminal.


**2.** Make a .env file with the following contents.

LOCAL_IP ="" //write your local IP connecting to the minio server with 9000 as port.
 
ACCESS_KEY="" // write your access key for minio server.

SECRET_KEY="" // write your secret key for minio server.


**3.** If your go file is showing error that you dont have minio package then run this command.
```
go get github.com/minio/minio-go/v7 
```

**4.** Run the go command to start golang backend.
```
go run file-uploader.go
```

## 📄 Running the frontend (Flutter)


**1.** Open the flutter folder in your android studio and in the code change the download and upload link with your local ip address with 8000 as port number.

**2.** Run the flutter file.
```
flutter run
```
## Maintainers
- 👤 **Sudeep Ranjan Sahoo** [@srs-sudeep](https://github.com/srs-sudeep)
- 👤 **Satvik** [@VickyMerzOwn](https://github.com/VickyMerzOwn)
- 👤 **Chaitanya** [@chaitanyabisht](https://github.com/chaitanyabisht)

---

