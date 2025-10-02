#!/bin/bash

# File Sharing App Docker Management Script

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
}

# Function to start all services
start_services() {
    print_status "Starting File Sharing Application services..."
    check_docker
    
    if [ ! -f "docker-compose.yml" ]; then
        print_error "docker-compose.yml not found. Please run this script from the project root directory."
        exit 1
    fi
    
    docker-compose up -d
    
    print_success "All services started successfully!"
    echo ""
    echo "🌐 Frontend (Flutter Web): http://localhost:3000"
    echo "🔧 Backend API: http://localhost:8000"
    echo "📦 MinIO Console: http://localhost:9001 (minioadmin/minioadmin123)"
    echo ""
    echo "To view logs: ./scripts/docker-manager.sh logs"
    echo "To stop services: ./scripts/docker-manager.sh stop"
}

# Function to stop all services
stop_services() {
    print_status "Stopping File Sharing Application services..."
    check_docker
    docker-compose down
    print_success "All services stopped successfully!"
}

# Function to restart all services
restart_services() {
    print_status "Restarting File Sharing Application services..."
    stop_services
    start_services
}

# Function to show logs
show_logs() {
    check_docker
    if [ -z "$2" ]; then
        print_status "Showing logs for all services..."
        docker-compose logs -f
    else
        print_status "Showing logs for $2 service..."
        docker-compose logs -f "$2"
    fi
}

# Function to show status
show_status() {
    check_docker
    print_status "Service status:"
    docker-compose ps
}

# Function to clean up
cleanup() {
    print_status "Cleaning up File Sharing Application..."
    check_docker
    docker-compose down -v
    docker system prune -f
    print_success "Cleanup completed!"
}

# Function to show help
show_help() {
    echo "File Sharing App Docker Management Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start     Start all services"
    echo "  stop      Stop all services"
    echo "  restart   Restart all services"
    echo "  logs      Show logs for all services"
    echo "  logs <service>  Show logs for specific service (backend, frontend, minio)"
    echo "  status    Show service status"
    echo "  cleanup   Stop services and clean up volumes and images"
    echo "  help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start"
    echo "  $0 logs backend"
    echo "  $0 status"
}

# Main script logic
case "${1:-help}" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    logs)
        show_logs "$@"
        ;;
    status)
        show_status
        ;;
    cleanup)
        cleanup
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac