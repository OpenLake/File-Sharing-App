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
2. [Docker Setup (Recommended)](#docker-setup-recommended)
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
- Powered by **MinIO** (object storage server) for efficient file handling.  
- **Tech Stack:**  
  - **Frontend:** Flutter  
  - **Backend:** GoLang  
  - **File Storage:** MinIO  

---

## Docker Setup (Recommended) <sup>[↥ Back to top](#table-of-contents)</sup>

The quickest way to get the entire File Sharing Application running is using Docker Compose. This will spin up all three services (Backend, Frontend, and MinIO) with a single command.

### 🐳 Prerequisites
- Docker and Docker Compose installed on your system
- At least 2GB of free disk space
- Ports 3000, 8000, 9000, and 9001 available on your machine

### 🚀 Quick Start
1. **Clone the repository:**
   ```bash
   git clone https://github.com/OpenLake/File-Sharing-App.git
   cd File-Sharing-App
   ```

2. **Start all services:**
   ```bash
   docker-compose up -d
   ```

3. **Access the services:**
   - **Frontend:** http://localhost:3000 (Web interface for file upload/download)
   - **Backend API:** http://localhost:8000 (REST API endpoints)
   - **MinIO Console:** http://localhost:9001 (Object storage admin interface)
   - **MinIO API:** http://localhost:9000 (Object storage API)

### 🔧 Environment Variables
The Docker setup uses the following default environment variables:
- `ACCESS_KEY=minioadmin` (MinIO access key)
- `SECRET_KEY=minioadmin123` (MinIO secret key)
- `LOCAL_IP=minio:9000` (MinIO endpoint for backend)

### 📝 Available Commands
```bash
# Start all services
docker-compose up -d

# View service status
docker-compose ps

# View logs
docker-compose logs [service-name]

# Stop all services
docker-compose down

# Stop and remove volumes (deletes uploaded files)
docker-compose down -v

# Rebuild services
docker-compose up -d --build
```

### 🧪 Testing the Setup
1. **Health Check:**
   ```bash
   curl http://localhost:8000/health
   # Should return "OK"
   ```

2. **Upload a file:**
   ```bash
   curl -X POST -F "file=@your-file.txt" http://localhost:8000/upload
   # Returns a presigned download URL
   ```

3. **Download a file:**
   ```bash
   curl "http://localhost:8000/download?filename=your-file.txt"
   # Returns a presigned download URL
   ```

### 🏗️ Architecture Overview
The Docker setup includes:
- **Backend Service** (Go): Handles file upload/download operations and integrates with MinIO
- **Frontend Service** (Static HTML): Simple web interface for testing file operations
- **MinIO Service**: Object storage compatible with AWS S3 API
- **Custom Network**: Enables secure inter-service communication
- **Persistent Volume**: Stores uploaded files across container restarts

---

## Getting Started <sup>[↥ Back to top](#table-of-contents)</sup>

### 🐳 Quick Start with Docker (Recommended)

The easiest way to get the entire stack running is using Docker Compose:

#### Prerequisites
- Docker and Docker Compose installed on your system
- At least 2GB of free disk space

#### Steps
1. **Clone the repository:**
   ```bash
   git clone https://github.com/OpenLake/File-Sharing-App.git
   cd File-Sharing-App
   ```

2. **Start all services:**
   ```bash
   docker-compose up -d
   ```

3. **Access the application:**
   - **Frontend (Flutter Web App):** http://localhost:3000
   - **Backend API:** http://localhost:8000
   - **MinIO Console:** http://localhost:9001 (admin/minioadmin123)

4. **Stop all services:**
   ```bash
   docker-compose down
   ```

#### Environment Variables
The application uses the following environment variables (see `.env.example`):

| Variable | Description | Default Value |
|----------|-------------|---------------|
| `MINIO_ROOT_USER` | MinIO admin username | `minioadmin` |
| `MINIO_ROOT_PASSWORD` | MinIO admin password | `minioadmin123` |
| `LOCAL_IP` | MinIO endpoint for backend | `minio:9000` |
| `ACCESS_KEY` | MinIO access key | `minioadmin` |
| `SECRET_KEY` | MinIO secret key | `minioadmin123` |
| `API_BASE_URL` | Backend API URL for frontend | `http://localhost:8000` |

#### Development Mode
For development with file watching and easier debugging:
```bash
# Copy environment variables
cp .env.example .env

# Start only MinIO and backend for development
docker-compose -f docker-compose.dev.yml up -d

# Run Flutter app locally
cd filesharing
flutter run -d web-server --web-port 3000
```

---

### 🛠️ Manual Setup (Alternative)

If you prefer to run services manually without Docker:

#### Prerequisites
- **MinIO Server** [Download](https://min.io/download)  
- **GoLang** (v1.19+) [Download](https://golang.org/dl/)  
- **Flutter** (v3.10+) [Download](https://flutter.dev/docs/get-started/install)  

#### Steps

##### 🗄️ Setting up MinIO
1. Download and start MinIO:
   ```bash
   # Linux/macOS
   wget https://dl.min.io/server/minio/release/linux-amd64/minio
   chmod +x minio
   ./minio server ~/minio-data --console-address ":9001"
   
   # Windows
   # Download minio.exe and run:
   # minio.exe server C:\minio-data --console-address ":9001"
   ```

2. Access MinIO Console at http://localhost:9001 (admin/minioadmin123)

##### ⚙️ Setting up Backend (GoLang)
1. Navigate to the Go directory:
   ```bash
   cd Go
   ```

2. Create a `.env` file:
   ```bash
   LOCAL_IP=localhost:9000
   ACCESS_KEY=minioadmin
   SECRET_KEY=minioadmin123
   ```

3. Install dependencies:
   ```bash
   go mod tidy
   ```

4. Start backend:
   ```bash
   go run file-uploader.go
   ```

##### � Setting up Frontend (Flutter)
1. Navigate to the Flutter directory:
   ```bash
   cd filesharing
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application:
   ```bash
   # For web
   flutter run -d web-server --web-port 3000
   
   # For mobile (requires device/emulator)
   flutter run
   ```

---

## Usage <sup>[↥ Back to top](#table-of-contents)</sup>

Once the setup is complete:  
- Upload files from one device via the Flutter app.  
- Files are stored in MinIO over your intranet.  
- Download files seamlessly on other connected devices.  

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
