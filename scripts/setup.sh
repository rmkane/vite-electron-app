#!/usr/bin/env bash

# Setup Script
# Initializes the project using Docker (no local Node.js required)

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPTS_DIR=$(dirname "$0")
PROJECT_DIR=$(dirname "$SCRIPTS_DIR")

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to display help
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -f, --full           Full setup: build Docker image and install dependencies"
    echo "  -b, --build          Build Docker image only"
    echo "  -i, --install        Install dependencies only (requires built image)"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                  # Full setup (default)"
    echo "  $0 -f               # Full setup (same as default)"
    echo "  $0 -b               # Build Docker image only"
    echo "  $0 -i               # Install dependencies only"
}

# Function to check if Docker is available
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first:"
        echo "  https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    if ! command -v docker compose &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first:"
        echo "  https://docs.docker.com/compose/install/"
        exit 1
    fi
    
    print_status "Docker and Docker Compose are available"
}

# Function to build Docker image
build_docker() {
    print_status "Building Docker image..."
    docker compose build
    print_status "Docker image built successfully"
}

# Function to install dependencies
install_dependencies() {
    print_status "Installing dependencies..."
    docker compose run --rm dev npm install
    print_status "Dependencies installed successfully"
}

# Function to do full setup
full_setup() {
    print_status "Starting full project setup..."
    
    check_docker
    build_docker
    install_dependencies
    
    print_status "Project setup complete!"
    print_status "You can now run:"
    echo "  npm run docker:dev    # Start development server"
    echo "  npm run docker:shell  # Get a shell in the container"
    echo "  npm run docker:build  # Build the application"
}

# Parse command line arguments
parse_args() {
    if [ $# -eq 0 ]; then
        # No arguments, do full setup
        full_setup
        return
    fi
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--full)
                full_setup
                return
                ;;
            -b|--build)
                check_docker
                build_docker
                ;;
            -i|--install)
                check_docker
                install_dependencies
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
        shift
    done
}

# Main execution
main() {
    print_status "Starting project setup..."
    parse_args "$@"
}

# Run main function with all arguments
main "$@" 