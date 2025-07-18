#!/usr/bin/env bash

# Sync Dependencies Script
# Ensures consistent dependencies across all platforms and Node versions

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
    echo "  -p, --platform PLATFORM    Target platform (linux, mac, windows, all)"
    echo "  -d, --docker               Use Docker for dependency sync"
    echo "  -l, --local                Use local Node.js"
    echo "  -h, --help                 Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                        # Sync for all platforms using Docker"
    echo "  $0 -p mac                 # Sync for macOS only"
    echo "  $0 -p windows -d          # Sync for Windows using Docker"
    echo "  $0 -l                     # Sync using local Node.js"
}

# Function to check Node version
check_node_version() {
    local node_version=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$node_version" -lt 18 ]; then
        print_warning "Node version $(node --version) detected. Node 18+ recommended for package-lock v2."
    fi
}

# Function to sync dependencies for a specific platform
sync_platform_deps() {
    local platform=$1
    local use_docker=$2
    
    print_status "Syncing dependencies for $platform..."
    
    if [ "$use_docker" = true ]; then
        # Use Docker with platform-specific environment
        case $platform in
            "mac")
                docker compose run --rm -e npm_config_target_platform=darwin dev npm install
                ;;
            "windows")
                docker compose run --rm -e npm_config_target_platform=win32 dev npm install
                ;;
            "linux")
                docker compose run --rm -e npm_config_target_platform=linux dev npm install
                ;;
            *)
                docker compose run --rm dev npm install
                ;;
        esac
    else
        # Use local Node.js with platform-specific environment
        case $platform in
            "mac")
                npm_config_target_platform=darwin npm install
                ;;
            "windows")
                npm_config_target_platform=win32 npm install
                ;;
            "linux")
                npm_config_target_platform=linux npm install
                ;;
            *)
                npm install
                ;;
        esac
    fi
    
    print_status "Dependencies synced for $platform"
}

# Function to sync all platforms
sync_all_platforms() {
    local use_docker=$1
    
    print_status "Syncing dependencies for all platforms..."
    
    # Remove existing lock file
    rm -f "$PROJECT_DIR/package-lock.json" 2>/dev/null || true
    rm -rf "$PROJECT_DIR/node_modules" 2>/dev/null || true
    
    # Sync for each platform
    sync_platform_deps "linux" "$use_docker"
    sync_platform_deps "mac" "$use_docker"
    sync_platform_deps "windows" "$use_docker"
    
    print_status "All platform dependencies synced!"
}

# Parse command line arguments
parse_args() {
    PLATFORM="all"
    USE_DOCKER=true  # Default to Docker for consistency
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--platform)
                PLATFORM="$2"
                shift 2
                ;;
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
    
    # Validate platform
    case $PLATFORM in
        linux|mac|windows|all)
            ;;
        *)
            print_error "Invalid platform: $PLATFORM"
            echo "Valid platforms: linux, mac, windows, all"
            exit 1
            ;;
    esac
    
    # Execute sync
    if [ "$PLATFORM" = "all" ]; then
        sync_all_platforms "$USE_DOCKER"
    else
        sync_platform_deps "$PLATFORM" "$USE_DOCKER"
    fi
}

# Main execution
main() {
    print_status "Starting dependency synchronization..."
    
    if [ "$USE_DOCKER" = false ]; then
        check_node_version
    fi
    
    parse_args "$@"
}

# Run main function with all arguments
main "$@" 