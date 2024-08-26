#!/bin/bash

# Load environment variables from $HOME/docker/.env file if it exists
if [ -f "$HOME/docker/.env" ]; then
    export $(cat "$HOME/docker/.env" | xargs)
else
    echo "Error: .env file not found in $HOME/docker/.env."
    echo "Please create one with the necessary variables."
    echo "Press Enter to return to the main menu..."
    read -r
    return 1
fi

# Function to display a banner
display_banner() {
    clear
    echo "======================================="
    echo "   Creating Dockerfile for $1"
    echo "======================================="
}

# Function to display error and prompt user
display_error() {
    echo "Error: $1"
    echo "Press Enter to return to the main menu..."
    read -r
    return 1
}

# Function to create Dockerfile and docker-compose.yml for a new platform
create_dockerfile() {
    local platform="$1"
    local platform_dir="$HOME/docker/$platform"

    # Display banner
    display_banner "$platform"

    # Create directory if it doesn't exist
    mkdir -p "$platform_dir" || { display_error "Failed to create directory for $platform"; return 1; }

    # Create a basic Dockerfile
    cat <<EOL > "${platform_dir}/Dockerfile"
FROM ${platform}:latest

WORKDIR /var/www/html

# Add your additional setup here
EOL

    # Create a basic docker-compose.yml
    cat <<EOL > "${platform_dir}/docker-compose.yml"
version: '3.8'

services:
  app:
    build: .
    ports:
      - "8080:80"
    volumes:
      - ./src:/var/www/html

  db:
    image: mysql:${MYSQL_VERSION}
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASSWORD}
      MYSQL_DATABASE: ${platform}_db
      MYSQL_USER: ${platform}_user
      MYSQL_PASSWORD: ${DB_USER_PASSWORD}
    volumes:
      - db_data:/var/lib/mysql

volumes:
  db_data:
EOL

    echo "Dockerfile and docker-compose.yml for ${platform} have been created successfully."
}

# Main script execution
create_dockerfile "$1"
