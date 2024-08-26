#!/bin/bash

# Ensure Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install Docker first."
    exit 1
fi

# Create a symbolic link to this script in $HOME/bin
ln -sf "$HOME/scripts/run-php-checks.sh" "$HOME/bin/php-checks"

# Function to display a banner
display_banner() {
    clear
    echo "======================================="
    echo "   Run PHP Checks Menu"
    echo "======================================="
}

# Function to display the menu
display_menu() {
    echo "Select an option:"
    echo ""
    echo "1. Run PHP CodeSniffer"
    echo "2. Run PHPStan"
    echo "3. Run both PHP CodeSniffer and PHPStan"
    echo "4. Quit"
}

# Main loop
while true; do
    display_banner
    display_menu
    read -rp "Enter your choice: " choice

    case $choice in
        1)
            read -rp "Enter the source path: " source_path
            docker run --rm -v "$source_path:/app" php-code-checker /app
            ;;
        2)
            read -rp "Enter the source path: " source_path
            docker run --rm -v "$source_path:/app" php-code-checker /app
            ;;
        3)
            read -rp "Enter the source path: " source_path
            docker run --rm -v "$source_path:/app" php-code-checker /app
            ;;
        4)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac
done
