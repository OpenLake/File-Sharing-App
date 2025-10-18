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
2. [Docker Setup](#docker-setup)
3. [Getting Started](#getting-started)
4. [Usage](#usage)
5. [Contributing](#contributing)
6. [Maintainers](#maintainers)
7. [License](#license)

---

## About the Project <sup>[↥ Back to top](#table-of-contents)</sup>

### 🤔 Problem  
We often need to transfer files between mobile and desktop devices. Typically, this is done using WhatsApp, Telegram, or other internet-based apps, which is inefficient for local transfers.  
This project enables **direct file sharing over an intranet** without requiring internet connectivity.  

### ✨ Features
- Cross-platform intranet file sharing between multiple devices.  
- **End-to-End Encryption** with AES-256-GCM for secure file transfers.  
- Client-side encryption and decryption for maximum security.  
- File integrity verification with SHA-256 hashing.  
- Powered by **MinIO** (object storage server) for efficient file handling.  
- **Tech Stack:**  
  - **Frontend:** Flutter  
  - **Backend:** GoLang  
  - **File Storage:** MinIO  
  - **Encryption:** AES-256-GCM with ECDH key exchange support  

---

## Docker Setup <sup>[↥ Back to top](#table-of-contents)</sup>

This project includes Docker support to easily run the entire stack with a single command.

### Prerequisites
- Docker and Docker Compose installed

### Quick Start
1. Clone the repository:
   ```bash
   git clone https://github.com/OpenLake/File-Sharing-App.git
   cd File-Sharing-App
   ```

2. Start all services:
   ```bash
   docker-compose up
   ```

3. Access the application:
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:8000
   - MinIO Console: http://localhost:9001

### Environment Variables
The setup uses these default environment variables:
- `ACCESS_KEY=minioadmin`
- `SECRET_KEY=minioadmin123`
- `LOCAL_IP=minio:9000`
---

## Getting Started <sup>[↥ Back to top](#table-of-contents)</sup>

For local development without Docker, you'll need to set up each service manually. You can follow the commands here.

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
- Files are automatically encrypted client-side using AES-256-GCM before upload.  
- Files are stored securely in MinIO over your intranet.  
- Download files seamlessly on other connected devices.  
- Files are automatically decrypted client-side after download with integrity verification.  

### 🔒 Security Features
- **Client-side encryption**: Files are encrypted before leaving your device
- **AES-256-GCM**: Industry-standard encryption algorithm
- **Integrity verification**: SHA-256 hashing ensures files haven't been tampered with
- **Unique keys**: Each file gets a unique encryption key
- See [ENCRYPTION.md](ENCRYPTION.md) for detailed security documentation  

### 🐳 Using Docker Setup
1. Start the application stack:
   ```bash
   docker-compose up -d
   ```

2. Open your web browser and navigate to http://localhost:3000

3. Upload and share files across your network!

### 🛠️ Using Manual Setup
Example (start backend in one terminal):  
```bash
cd Go
go run file-uploader.go
```

And then run the frontend Flutter app:
```bash
cd filesharing
flutter run -d web-server --web-port 3000
```

---

## Troubleshooting <sup>[↥ Back to top](#table-of-contents)</sup>

### Docker Issues
- **Port conflicts:** If ports 3000, 8000, 9000, or 9001 are in use, modify the port mappings in `docker-compose.yml`
- **Build failures:** Ensure Docker has enough memory allocated (recommended: 4GB+)
- **Permission issues:** On Linux, you may need to run Docker commands with `sudo`

### Common Issues
- **Frontend can't connect to backend:** Verify the `API_BASE_URL` is correctly set
- **MinIO connection fails:** Check if MinIO service is running and accessible
- **File upload fails:** Ensure proper CORS headers and file size limits

### Logs and Debugging
```bash
# View all service logs
docker-compose logs

# View specific service logs
docker-compose logs backend
docker-compose logs frontend
docker-compose logs minio

# Follow logs in real-time
docker-compose logs -f
```

---

## Contributing <sup>[↥ Back to top](#table-of-contents)</sup>

We welcome contributions from the community! 🎉  
Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines before submitting a pull request.  

---

## Maintainers <sup>[↥ Back to top](#table-of-contents)</sup>

- 👤 **Ashish Kumar Dash**  
  [@ashish-kumar-dash](https://github.com/ashish-kumar-dash)
- 👤 **Sri Varshith**  
  [@Sri-Varshith](https://github.com/Sri-Varshith)

See [MAINTAINERS.md](MAINTAINERS.md) for the full list.

---

## License <sup>[↥ Back to top](#table-of-contents)</sup>

Distributed under the **MIT License**.  
See [LICENSE](LICENSE) for details. 
