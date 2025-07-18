#!/usr/bin/env bash

# Clean Script
# Removes all build artifacts, dependencies, and Docker containers

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
    echo "  -b, --build         Clean build artifacts only (default)"
    echo "  -f, --full          Full clean: everything including node_modules"
    echo "  -d, --docker        Clean Docker containers and images"
    echo "  -n, --node          Clean node_modules only"
    echo "  -a, --all           Clean everything (same as --full)"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                  # Clean build artifacts (default)"
    echo "  $0 -b               # Clean build artifacts only"
    echo "  $0 -f               # Full clean (everything)"
    echo "  $0 -d -n            # Clean Docker and node_modules"
}

# Function to clean build artifacts
clean_build_artifacts() {
    print_status "Cleaning build artifacts..."
    
    # Remove build directories
    rm -rf "$PROJECT_DIR/dist" 2>/dev/null || true
    rm -rf "$PROJECT_DIR/build" 2>/dev/null || true
    
    # Remove TypeScript build artifacts
    rm -rf "$PROJECT_DIR/.tsbuildinfo" 2>/dev/null || true
    
    # Remove Vite cache
    rm -rf "$PROJECT_DIR/node_modules/.vite" 2>/dev/null || true
    
    print_status "Build artifacts cleaned"
}

# Function to clean Docker containers and images
clean_docker() {
    print_status "Cleaning Docker containers and images..."
    
    # Stop and remove containers
    docker compose down --remove-orphans 2>/dev/null || true
    
    # Remove containers with our app name
    docker ps -a --filter "name=vite-electron" --format "{{.ID}}" | xargs -r docker rm -f 2>/dev/null || true
    
    # Remove images
    docker images --filter "reference=vite-electron-app*" --format "{{.ID}}" | xargs -r docker rmi -f 2>/dev/null || true
    
    # Remove dangling images
    docker image prune -f 2>/dev/null || true
    
    # Remove unused volumes
    docker volume prune -f 2>/dev/null || true
    
    print_status "Docker containers and images cleaned"
}

# Function to clean node_modules only
clean_node() {
    print_status "Cleaning node_modules..."
    
    # Remove node_modules only (preserve package-lock.json)
    rm -rf "$PROJECT_DIR/node_modules" 2>/dev/null || true
    
    print_status "Node modules cleaned"
}



# Function to clean everything (full clean)
clean_full() {
    print_status "Starting full cleanup..."
    
    clean_build_artifacts
    clean_docker
    clean_node
    
    # Additional cleanup
    print_status "Cleaning additional files..."
    
    # Remove log files
    find "$PROJECT_DIR" -name "*.log" -type f -delete 2>/dev/null || true
    
    # Remove temporary files
    find "$PROJECT_DIR" -name "*.tmp" -type f -delete 2>/dev/null || true
    find "$PROJECT_DIR" -name "*.temp" -type f -delete 2>/dev/null || true
    
    # Remove OS-specific files
    find "$PROJECT_DIR" -name ".DS_Store" -type f -delete 2>/dev/null || true
    find "$PROJECT_DIR" -name "Thumbs.db" -type f -delete 2>/dev/null || true
    
    print_status "Full cleanup finished!"
}

# Function to clean build artifacts only (default)
clean_default() {
    print_status "Starting cleanup..."
    
    clean_build_artifacts
    
    print_status "Cleanup finished!"
}

# Parse command line arguments
parse_args() {
    CLEAN_BUILD=false
    CLEAN_DOCKER=false
    CLEAN_NODE=false
    
    if [ $# -eq 0 ]; then
        # No arguments, default clean (build artifacts only)
        clean_default
        return
    fi
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--full)
                clean_full
                return
                ;;
            -a|--all)
                clean_full
                return
                ;;
            -b|--build)
                CLEAN_BUILD=true
                shift
                ;;
            -d|--docker)
                CLEAN_DOCKER=true
                shift
                ;;
            -n|--node)
                CLEAN_NODE=true
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
    
    # Execute selected clean operations
    if [ "$CLEAN_BUILD" = true ]; then
        clean_build_artifacts
    fi
    
    if [ "$CLEAN_DOCKER" = true ]; then
        clean_docker
    fi
    
    if [ "$CLEAN_NODE" = true ]; then
        clean_node
    fi
    
    print_status "Selected cleanup operations completed!"
}

# Main execution
main() {
    print_status "Starting cleanup process..."
    parse_args "$@"
}

# Run main function with all arguments
main "$@" 