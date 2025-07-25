#!/bin/bash

# Multi-Project Laravel Claude Code Setup Installer
# Supports project structures like:
# project/
#   ├── api/      (Laravel backend)
#   └── webapp/   (Vue frontend)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in a project with the expected structure
check_project_structure() {
    local api_dir=""
    local webapp_dir=""
    
    # Check common patterns for Laravel API directory
    for dir in api backend laravel-api server; do
        if [ -d "$dir" ] && [ -f "$dir/artisan" ] && [ -f "$dir/composer.json" ]; then
            api_dir="$dir"
            break
        fi
    done
    
    # Check common patterns for frontend directory
    for dir in webapp frontend client vue-app web app; do
        if [ -d "$dir" ] && [ -f "$dir/package.json" ]; then
            webapp_dir="$dir"
            break
        fi
    done
    
    if [ -z "$api_dir" ]; then
        print_error "No Laravel API directory found!"
        print_error "Expected structure: project/api/ (or similar) containing artisan and composer.json"
        echo ""
        echo "Common directory names checked: api, backend, laravel-api, server"
        exit 1
    fi
    
    if [ -z "$webapp_dir" ]; then
        print_error "No frontend directory found!"
        print_error "Expected structure: project/webapp/ (or similar) containing package.json"
        echo ""
        echo "Common directory names checked: webapp, frontend, client, vue-app, web, app"
        exit 1
    fi
    
    print_success "Found project structure:"
    echo "  - Laravel API: $api_dir/"
    echo "  - Frontend: $webapp_dir/"
    echo ""
    
    # Export for use in other functions
    export LARAVEL_DIR="$api_dir"
    export FRONTEND_DIR="$webapp_dir"
}

# Download the multi-project setup script
download_setup_script() {
    print_status "Downloading multi-project setup script..."
    
    # Create a temporary directory
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # Download the setup script
    if command -v curl &> /dev/null; then
        curl -fsSL https://raw.githubusercontent.com/advalis/laravel-claude-code-setup/main/scripts/setup-claude-code-multi.sh -o setup.sh
    elif command -v wget &> /dev/null; then
        wget -q https://raw.githubusercontent.com/advalis/laravel-claude-code-setup/main/scripts/setup-claude-code-multi.sh -O setup.sh
    else
        print_error "Neither curl nor wget found. Please install one of them."
        exit 1
    fi
    
    chmod +x setup.sh
    
    # Return to original directory
    cd - > /dev/null
    
    # Export temp directory for cleanup later
    export TEMP_SETUP_DIR="$TEMP_DIR"
}

# Main installation
main() {
    echo -e "${BLUE}Laravel Multi-Project Claude Code Setup${NC}"
    echo "========================================"
    echo ""
    
    # Check project structure
    check_project_structure
    
    # Download setup script
    download_setup_script
    
    # Run the setup script with our detected directories
    print_status "Running multi-project setup..."
    bash "$TEMP_SETUP_DIR/setup.sh" "$LARAVEL_DIR" "$FRONTEND_DIR"
    
    # Cleanup
    rm -rf "$TEMP_SETUP_DIR"
    
    print_success "Multi-project setup complete!"
    echo ""
    echo "To start using Claude Code with your project:"
    echo "  1. Make sure Claude Code is running"
    echo "  2. From this directory, run: claude"
    echo ""
    echo "Claude Code will have access to both your Laravel API and frontend code!"
}

# Run main
main "$@"