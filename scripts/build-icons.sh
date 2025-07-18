#!/usr/bin/env bash

# Build Icons Script
# Converts icon.svg to PNG, ICO, and ICNS formats using ImageMagick

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPTS_DIR=$(dirname "$0")
PROJECT_DIR=$(dirname "$SCRIPTS_DIR")
ASSETS_DIR="$PROJECT_DIR/assets"
ICONSET_DIR="$ASSETS_DIR/icon.iconset"

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

# Function to convert SVG to a specific size
convert_svg() {
    local size=$1
    local output_file=$2
    print_status "Converting to $output_file (${size}x${size})..."
    # Use density to improve SVG rendering quality and preserve transparency
    magick -density 300 \
        -background transparent \
        "$ASSETS_DIR/icon.svg" \
        -resize "${size}x${size}" \
        -quality 100 \
        -alpha set \
        "$output_file"
}

# Function to build Windows icon (ICO)
build_windows_icon() {
    print_status "Building Windows icon..."
    # Create ICO with multiple sizes for better quality and transparency
    magick -density 300 -background transparent "$ASSETS_DIR/icon.svg" \
        \( -clone 0 -resize 16x16 \) \
        \( -clone 0 -resize 32x32 \) \
        \( -clone 0 -resize 48x48 \) \
        \( -clone 0 -resize 64x64 \) \
        \( -clone 0 -resize 128x128 \) \
        \( -clone 0 -resize 256x256 \) \
        -delete 0 -colors 256 "$ASSETS_DIR/icon.ico"
}

# Function to build Linux icon (PNG)
build_linux_icon() {
    print_status "Building Linux icon..."
    convert_svg 512 "$ASSETS_DIR/icon.png"
}

# Function to build macOS icon (ICNS)
build_macos_icon() {
    print_status "Building macOS icon..."
    
    # Create temporary iconset directory
    mkdir -p "$ICONSET_DIR"
    
    # Define all required sizes for macOS
    local macos_icon_sizes=(
        "16:16"
        "32:16@2x"
        "32:32"
        "64:32@2x"
        "128:128"
        "256:128@2x"
        "256:256"
        "512:256@2x"
        "512:512"
        "1024:512@2x"
    )
    
    # Generate all required sizes
    for size_info in "${macos_icon_sizes[@]}"; do
        IFS=':' read -r size filename <<< "$size_info"
        convert_svg "$size" "$ICONSET_DIR/icon_${filename}.png"
    done
    
    # Convert iconset to ICNS
    print_status "Converting iconset to ICNS..."
    iconutil -c icns "$ICONSET_DIR" -o "$ASSETS_DIR/icon.icns"
    
    # Clean up temporary iconset directory
    rm -rf "$ICONSET_DIR"
}

# Function to update package.json
update_package_json() {
    print_status "Updating package.json..."
    if [ -f "$PROJECT_DIR/package.json" ]; then
        # Update macOS icon path specifically
        sed -i '' '/"mac": {/,/}/ s/"icon": "assets\/icon.png"/"icon": "assets\/icon.icns"/' "$PROJECT_DIR/package.json"
        print_status "Updated package.json to use assets/icon.icns for macOS"
    fi
}

# Function to display help
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -p, --platform PLATFORM    Build icons for specific platform (windows, linux, mac, all)"
    echo "  -s, --size SIZE            Custom size for single platform builds (default: platform-specific)"
    echo "  -o, --output DIR           Output directory (default: assets/)"
    echo "  -h, --help                 Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                        # Build all platforms"
    echo "  $0 -p mac                 # Build only macOS icons"
    echo "  $0 -p windows -s 512      # Build Windows icon at 512x512"
    echo "  $0 -p linux -o custom/    # Build Linux icon in custom directory"
    echo ""
    echo "Platforms:"
    echo "  windows    - Creates icon.ico (256x256)"
    echo "  linux      - Creates icon.png (512x512)"
    echo "  mac        - Creates icon.icns (multi-size)"
    echo "  all        - Creates all formats (default)"
}

# Function to display results
show_results() {
    local platform=$1
    print_status "Icon conversion complete!"
    print_status "Generated files:"
    
    case $platform in
        "windows")
            echo "  - $ASSETS_DIR/icon.ico (256x256) - Windows"
            ;;
        "linux")
            echo "  - $ASSETS_DIR/icon.png (512x512) - Linux"
            ;;
        "mac")
            echo "  - $ASSETS_DIR/icon.icns (multi-size) - macOS"
            ;;
        "all"|*)
            echo "  - $ASSETS_DIR/icon.png (512x512) - Linux"
            echo "  - $ASSETS_DIR/icon.ico (256x256) - Windows"
            echo "  - $ASSETS_DIR/icon.icns (multi-size) - macOS"
            ;;
    esac
}

# Function to build custom size icon
build_custom_icon() {
    local target_platform=$1
    local icon_size=$2
    local output_directory=${3:-$ASSETS_DIR}
    
    print_status "Building custom $target_platform icon (${icon_size}x${icon_size})..."
    mkdir -p "$output_directory"
    
    case $target_platform in
        "windows")
            convert_svg "$icon_size" "$output_directory/icon.ico"
            ;;
        "linux")
            convert_svg "$icon_size" "$output_directory/icon.png"
            ;;
        "mac")
            print_warning "Custom size not supported for macOS (uses multi-size ICNS)"
            build_macos_icon
            ;;
    esac
}

# Parse command line arguments
parse_args() {
    PLATFORM="all"
    CUSTOM_SIZE=""
    OUTPUT_DIR=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--platform)
                PLATFORM="$2"
                shift 2
                ;;
            -s|--size)
                CUSTOM_SIZE="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_DIR="$2"
                shift 2
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
        windows|linux|mac|all)
            ;;
        *)
            print_error "Invalid platform: $PLATFORM"
            echo "Valid platforms: windows, linux, mac, all"
            exit 1
            ;;
    esac
    
    # Update ASSETS_DIR if custom output specified
    if [ -n "$OUTPUT_DIR" ]; then
        ASSETS_DIR="$OUTPUT_DIR"
        ICONSET_DIR="$ASSETS_DIR/icon.iconset"
    fi
}

# Main execution
main() {
    # Parse command line arguments
    parse_args "$@"
    
    # Check if ImageMagick is installed
if ! command -v magick &> /dev/null; then
    print_error "ImageMagick is not installed. Please install it first:"
    echo "  brew install imagemagick"
    exit 1
fi

# Check ImageMagick SVG support
if ! magick -list format | grep -q "SVG"; then
    print_warning "ImageMagick SVG support not detected. For best results, install with SVG support:"
    echo "  brew install imagemagick --with-librsvg"
fi

    # Check if icon.svg exists
    if [ ! -f "$ASSETS_DIR/icon.svg" ]; then
        print_error "assets/icon.svg not found!"
        exit 1
    fi

    print_status "Starting icon conversion for platform: $PLATFORM"

    # Create assets directory if it doesn't exist
    mkdir -p "$ASSETS_DIR"

    # Build icons based on platform selection
    case $PLATFORM in
        "windows")
            if [ -n "$CUSTOM_SIZE" ]; then
                build_custom_icon "windows" "$CUSTOM_SIZE" "$OUTPUT_DIR"
            else
                build_windows_icon
            fi
            ;;
        "linux")
            if [ -n "$CUSTOM_SIZE" ]; then
                build_custom_icon "linux" "$CUSTOM_SIZE" "$OUTPUT_DIR"
            else
                build_linux_icon
            fi
            ;;
        "mac")
            build_macos_icon
            ;;
        "all"|*)
            build_windows_icon
            build_linux_icon
            build_macos_icon
            ;;
    esac
    
    # Update package.json only if building all or macOS
    if [ "$PLATFORM" = "all" ] || [ "$PLATFORM" = "mac" ]; then
        update_package_json
    fi
    
    # Show results
    show_results "$PLATFORM"
}

# Run main function with all arguments
main "$@" 