<h1 align="center">Welcome to the File Sharing Application 👋</h1>
<p align="center">
A cross-platform intranet-based file sharing application built with Flutter, GoLang, and MinIO.
</p>
<p align="center">
    <img src="https://img.shields.io/badge/Status-Deployed-brightgreen" alt="Status: Deployed" />
    <img src="https://img.shields.io/badge/Development-Ongoing-blue" alt="Development: Ongoing" />
    <img src="https://img.shields.io/badge/License-MIT-yellow" alt="License: MIT" />
</p>
<p align="center">
    <img src="https://img.shields.io/github/issues-pr-closed/ashish-kumar-dash/file-sharing-app?color=success" alt="Pull Requests Merged" />
    <img src="https://img.shields.io/github/issues/ashish-kumar-dash/file-sharing-app?color=orange" alt="Open Issues" />
    <img src="https://img.shields.io/github/contributors/ashish-kumar-dash/file-sharing-app" alt="Contributors" />
</p>

---

## Repository Links <sup>[↥ Back to top](#table-of-contents)</sup>
- **Main Repository:** [OpenLake](https://github.com/OpenLake)
- **This Project Repository:** [File Sharing Application](https://github.com/ashish-kumar-dash/file-sharing-app)
- **Discord** [Discord](https://discord.gg/tNcwTQ5Q43)

---

## Table of Contents
1. [About the Project](#about-the-project)
2. [Getting Started](#getting-started)
3. [Usage](#usage)
4. [Contributing](#contributing)
5. [Maintainers](#maintainers)
6. [License](#license)

---

## About the Project <sup>[↥ Back to top](#table-of-contents)</sup>

### 🤔 Problem  
We often need to transfer files between mobile and desktop devices. Typically, this is done using WhatsApp, Telegram, or other internet-based apps, which is inefficient for local transfers.  
This project enables **direct file sharing over an intranet** without requiring internet connectivity.  

### ✨ Features
- Cross-platform intranet file sharing between multiple devices.  
- Powered by **MinIO** (object storage server) for efficient file handling.  
- **Tech Stack:**  
  - **Frontend:** Flutter  
  - **Backend:** GoLang  
  - **File Storage:** MinIO  

---

## Getting Started <sup>[↥ Back to top](#table-of-contents)</sup>

### Prerequisites
Make sure you have the following installed:
- [Go](https://go.dev) (>=1.18)  
- [Flutter](https://flutter.dev) (>=3.0)  
- [MinIO](https://min.io)  

---

### 📄 Running MinIO Server
1. Create a directory for MinIO:
mkdir ~/minio

2. Run the server on port **9090**:
minio server ~/minio --console-address :9090

---

### 📄 Running Backend (Go)
1. Navigate to the Go backend folder:
cd backend

2. Create a `.env` file with:
LOCAL_IP="" # Your local IP connected with minio (port 9000)
ACCESS_KEY="" # MinIO access key
SECRET_KEY="" # MinIO secret key

3. Install MinIO Go SDK if missing:
go get github.com/minio/minio-go/v7

4. Start backend:
go run file-uploader.go

---

### 📄 Running Frontend (Flutter)
1. Open the Flutter project in **Android Studio**.  
2. Update the upload/download endpoint IPs in the code with your local IP (port `8000`).  
3. Run the application:
flutter run

---

## Usage <sup>[↥ Back to top](#table-of-contents)</sup>

Once the setup is complete:  
- Upload files from one device via the Flutter app.  
- Files are stored in MinIO over your intranet.  
- Download files seamlessly on other connected devices.  

Example (start backend in one terminal):  
go run file-uploader.go


And then run the frontend Flutter app:
flutter run

---

## Contributing <sup>[↥ Back to top](#table-of-contents)</sup>

We welcome contributions from the community! 🎉  
Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines before submitting a pull request.  

---

## Maintainers <sup>[↥ Back to top](#table-of-contents)</sup>

- 👤 **Ashish Kumar Dash**  
  [@ashish-kumar-dash](https://github.com/ashish-kumar-dash)

See [MAINTAINERS.md](MAINTAINERS.md) for the full list.

---

## License <sup>[↥ Back to top](#table-of-contents)</sup>

Distributed under the **MIT License**.  
See [LICENSE](LICENSE) for details. 