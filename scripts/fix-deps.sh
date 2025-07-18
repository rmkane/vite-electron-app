#!/usr/bin/env bash

# Fix Dependencies Script
# Regenerates package-lock.json to fix platform-specific dependency issues

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
    echo "  -d, --docker        Use Docker to fix dependencies"
    echo "  -l, --local         Use local Node.js to fix dependencies"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                  # Use Docker (default)"
    echo "  $0 -d               # Use Docker explicitly"
    echo "  $0 -l               # Use local Node.js"
}

# Function to fix dependencies using Docker
fix_deps_docker() {
    print_status "Fixing dependencies using Docker..."
    
    # Remove existing node_modules and package-lock.json
    print_status "Removing existing dependencies..."
    rm -rf "$PROJECT_DIR/node_modules" 2>/dev/null || true
    rm -f "$PROJECT_DIR/package-lock.json" 2>/dev/null || true
    
    # Build Docker image if not exists
    print_status "Building Docker image..."
    docker compose build --no-cache
    
    # Install dependencies in Docker
    print_status "Installing dependencies in Docker..."
    docker compose run --rm dev npm install
    
    print_status "Dependencies fixed using Docker!"
}

# Function to fix dependencies using local Node.js
fix_deps_local() {
    print_status "Fixing dependencies using local Node.js..."
    
    # Check if Node.js is available
    if ! command -v node &> /dev/null; then
        print_error "Node.js is not installed locally. Use -d flag for Docker."
        exit 1
    fi
    
    if ! command -v npm &> /dev/null; then
        print_error "npm is not installed locally. Use -d flag for Docker."
        exit 1
    fi
    
    # Remove existing node_modules and package-lock.json
    print_status "Removing existing dependencies..."
    rm -rf "$PROJECT_DIR/node_modules" 2>/dev/null || true
    rm -f "$PROJECT_DIR/package-lock.json" 2>/dev/null || true
    
    # Install dependencies locally
    print_status "Installing dependencies locally..."
    npm install
    
    print_status "Dependencies fixed using local Node.js!"
}

# Parse command line arguments
parse_args() {
    USE_DOCKER=true  # Default to Docker
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--docker)
                USE_DOCKER=true
                shift
                ;;
            -l|--local)
                USE_DOCKER=false
                shift
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
    done
    
    # Execute the appropriate fix
    if [ "$USE_DOCKER" = true ]; then
        fix_deps_docker
    else
        fix_deps_local
    fi
}

# Main execution
main() {
    print_status "Starting dependency fix..."
    parse_args "$@"
}

# Run main function with all arguments
main "$@" 