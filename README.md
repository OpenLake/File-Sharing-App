<h1 align="center">Welcome to the File Sharing Application👋</h1>


## 🤔 Problem
We often have to transfer files between our mobile and desktop devices. But generally we do it with WhatsApp, Telegram or some other application which passes through the internet. We can create a mobile-app for use on our institutes intranet.

## ✨ Features
- Cross platform application to share files between devices across an intranet. 
- Use of object storage server to share files.
- Tech Stack : Flutter, GoLang , Minio

## 📄 Running Server of Minio

Run the server of Minio in a terminal.
**1.** 
```
mkdir ~/minio
```
**2.** 
```
minio server ~/minio --console-address :9090
```
## 📄 Running the backend (Go)

cd to Go folder and run the backend in a separate terminal.
**1.** 

Make a .env file with the following contents
LOCAL_IP ="" //write your local IP connecting to the minio server with 9000 as port
ACCESS_KEY="" // write your access key for minio server
SECRET_KEY="" // write your secret key for minio server

**2.** 
```
go get github.com/minio/minio-go/v7 //If your go file is showing error that you dont have minio package then run this command.
```
**3.** 
```go run file-uploader.go
```
## 📄 Running the frontend (Flutter)

Open the flutter folder in your android studio  and run this command in the terminal.
**1.** 
```
In the code change the download and upload link with your local ip address with 8000 as port number.
```
**2.** 
```
flutter run
```
## Maintainers

- 👤 **Satvik** [@VickyMerzOwn](https://github.com/VickyMerzOwn)
- 👤 **Chaitanya** [@chaitanyabisht](https://github.com/chaitanyabisht)

---

