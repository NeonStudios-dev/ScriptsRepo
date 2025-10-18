#!/bin/bash
# Advanced Multi-Platform .NET Build Script for Linux
# Builds for Windows, macOS (x64/ARM64), and Linux

set -e

# Default Configuration
PROJECT_PATH="."
OUTPUT_DIR="./builds"
CONFIGURATION="Release"
SELF_CONTAINED=true
SINGLE_FILE=true
TRIMMED=false
SKIP_CLEAN=false
VERBOSE=false
PARALLEL=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--project)
            PROJECT_PATH="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -c|--configuration)
            CONFIGURATION="$2"
            shift 2
            ;;
        --no-self-contained)
            SELF_CONTAINED=false
            shift
            ;;
        --no-single-file)
            SINGLE_FILE=false
            shift
            ;;
        -t|--trimmed)
            TRIMMED=true
            shift
            ;;
        --skip-clean)
            SKIP_CLEAN=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        --parallel)
            PARALLEL=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -p, --project PATH          Path to project directory (default: current directory)"
            echo "  -o, --output DIR            Output directory for builds (default: ./builds)"
            echo "  -c, --configuration CONFIG  Build configuration: Release or Debug (default: Release)"
            echo "  --no-self-contained         Don't include .NET runtime (framework-dependent)"
            echo "  --no-single-file            Don't bundle as single file"
            echo "  -t, --trimmed               Enable trimming to reduce size"
            echo "  --skip-clean                Don't clean previous builds"
            echo "  -v, --verbose               Show detailed build output"
            echo "  --parallel                  Build platforms in parallel (experimental)"
            echo "  -h, --help                  Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                                           # Build with defaults"
            echo "  $0 -p ./src/MyApp -o ./dist -c Debug        # Custom paths and config"
            echo "  $0 --trimmed --verbose                       # Trimmed build with verbose output"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Save the original working directory
ORIGINAL_DIR="$(pwd)"

# Helper functions
print_status() { echo -e "${CYAN}>>> $1${NC}"; }
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }

# Find .csproj file
# If PROJECT_PATH is relative and doesn't start with /, make it relative to original directory
if [[ "$PROJECT_PATH" != /* ]]; then
    PROJECT_PATH="$ORIGINAL_DIR/$PROJECT_PATH"
fi

if [ ! -d "$PROJECT_PATH" ]; then
    print_error "Project path not found: $PROJECT_PATH"
    exit 1
fi

PROJECT_FILE=$(find "$PROJECT_PATH" -maxdepth 1 -name "*.csproj" | head -n 1)
if [ -z "$PROJECT_FILE" ]; then
    print_error "No .csproj file found in $PROJECT_PATH"
    exit 1
fi

PROJECT_NAME=$(basename "$PROJECT_FILE" .csproj)

# Make OUTPUT_DIR absolute if it's relative
if [[ "$OUTPUT_DIR" != /* ]]; then
    OUTPUT_DIR="$ORIGINAL_DIR/$OUTPUT_DIR"
fi

print_status "Building project: $PROJECT_NAME"
print_status "Configuration: $CONFIGURATION"
print_status "Self-contained: $SELF_CONTAINED"
print_status "Single file: $SINGLE_FILE"
echo ""

# Clean previous builds
if [ "$SKIP_CLEAN" = false ] && [ -d "$OUTPUT_DIR" ]; then
    print_status "Cleaning previous builds..."
    rm -rf "$OUTPUT_DIR"
fi

mkdir -p "$OUTPUT_DIR"

# Build targets: OS, Architecture, RID
declare -a BUILDS=(
    "Windows:x64:win-x64"
    "Windows:ARM64:win-arm64"
    "macOS:x64:osx-x64"
    "macOS:ARM64:osx-arm64"
    "Linux:x64:linux-x64"
    "Linux:ARM64:linux-arm64"
)

SUCCESS_COUNT=0
FAIL_COUNT=0

# Function to build a single platform
build_platform() {
    local build_config=$1
    IFS=':' read -r OS ARCH RID <<< "$build_config"
    
    BUILD_NAME="${PROJECT_NAME}_${OS}_${ARCH}"
    BUILD_PATH="$OUTPUT_DIR/temp_$BUILD_NAME"
    
    print_status "Building $BUILD_NAME ($RID)..."
    
    # Construct dotnet publish command
    PUBLISH_ARGS=(
        "publish"
        "$PROJECT_FILE"
        "-c" "$CONFIGURATION"
        "-r" "$RID"
        "-o" "$BUILD_PATH"
        "--nologo"
    )
    
    if [ "$SELF_CONTAINED" = true ]; then
        PUBLISH_ARGS+=("--self-contained" "true")
    else
        PUBLISH_ARGS+=("--self-contained" "false")
    fi
    
    if [ "$SINGLE_FILE" = true ]; then
        PUBLISH_ARGS+=("-p:PublishSingleFile=true")
    fi
    
    if [ "$TRIMMED" = true ]; then
        PUBLISH_ARGS+=("-p:PublishTrimmed=true")
    fi
    
    # Execute build
    if [ "$VERBOSE" = true ]; then
        BUILD_OUTPUT=$(dotnet "${PUBLISH_ARGS[@]}" 2>&1)
        BUILD_RESULT=$?
    else
        BUILD_OUTPUT=$(dotnet "${PUBLISH_ARGS[@]}" 2>&1 > /dev/null)
        BUILD_RESULT=$?
    fi
    
    if [ $BUILD_RESULT -eq 0 ]; then
        print_success "Build completed: $BUILD_NAME"
        
        # Create zip archive
        ZIP_NAME="${BUILD_NAME}.zip"
        ZIP_PATH="$OUTPUT_DIR/$ZIP_NAME"
        
        print_status "Creating archive: $ZIP_NAME"
        
        (cd "$BUILD_PATH" && zip -r -q "$ZIP_PATH" .)
        
        if [ -f "$ZIP_PATH" ]; then
            SIZE=$(du -h "$ZIP_PATH" | cut -f1)
            print_success "Archive created: $ZIP_NAME ($SIZE)"
            echo "success" > "$OUTPUT_DIR/.result_$BUILD_NAME"
        else
            print_error "Failed to create archive: $ZIP_NAME"
            echo "fail" > "$OUTPUT_DIR/.result_$BUILD_NAME"
        fi
        
        # Clean up temp build directory
        rm -rf "$BUILD_PATH"
    else
        print_error "Build failed: $BUILD_NAME"
        if [ "$VERBOSE" = true ]; then
            echo "$BUILD_OUTPUT"
        fi
        echo "fail" > "$OUTPUT_DIR/.result_$BUILD_NAME"
    fi
    
    echo ""
}

# Build each platform
if [ "$PARALLEL" = true ]; then
    print_warning "Building in parallel mode..."
    for build_config in "${BUILDS[@]}"; do
        build_platform "$build_config" &
    done
    wait
    
    # Count results
    for build_config in "${BUILDS[@]}"; do
        IFS=':' read -r OS ARCH RID <<< "$build_config"
        BUILD_NAME="${PROJECT_NAME}_${OS}_${ARCH}"
        if [ -f "$OUTPUT_DIR/.result_$BUILD_NAME" ]; then
            RESULT=$(cat "$OUTPUT_DIR/.result_$BUILD_NAME")
            if [ "$RESULT" = "success" ]; then
                ((SUCCESS_COUNT++))
            else
                ((FAIL_COUNT++))
            fi
            rm "$OUTPUT_DIR/.result_$BUILD_NAME"
        fi
    done
else
    for build_config in "${BUILDS[@]}"; do
        build_platform "$build_config"
        if [ -f "$OUTPUT_DIR/.result_${PROJECT_NAME}_"* ]; then
            RESULT=$(cat "$OUTPUT_DIR/.result_"*)
            if [ "$RESULT" = "success" ]; then
                ((SUCCESS_COUNT++))
            else
                ((FAIL_COUNT++))
            fi
            rm "$OUTPUT_DIR/.result_"*
        fi
    done
fi

# Summary
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}Build Summary:${NC}"
echo -e "${CYAN}========================================${NC}"
print_success "Successful: $SUCCESS_COUNT"
if [ $FAIL_COUNT -gt 0 ]; then
    print_error "Failed: $FAIL_COUNT"
fi
echo -e "${CYAN}Output directory: $OUTPUT_DIR${NC}"
echo ""

# List all created archives
if [ $SUCCESS_COUNT -gt 0 ]; then
    print_status "Created archives:"
    for zip_file in "$OUTPUT_DIR"/*.zip; do
        if [ -f "$zip_file" ]; then
            SIZE=$(du -h "$zip_file" | cut -f1)
            echo -e "  - $(basename "$zip_file") ($SIZE)"
        fi
    done
fi

exit $FAIL_COUNT
