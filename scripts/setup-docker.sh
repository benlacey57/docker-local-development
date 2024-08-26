#!/bin/bash

# Load environment variables from $HOME/docker/.env file if it exists
if [ -f "$HOME/docker/.env" ]; then
    export $(cat "$HOME/docker/.env" | xargs)
else
    echo ""
    echo "Error: .env file not found in $HOME/docker/.env."
    echo "Please create one with the necessary variables."
    echo ""
    echo "Press Enter to return to the main menu..."
    read -r
    exit 1
fi

# Function to display a banner
display_banner() {
    clear
    echo "======================================="
    echo "   $1"
    echo "======================================="
}

# Function to display error and prompt user
display_error() {
    echo ""
    echo "Error: $1"
    echo ""
    echo "Press Enter to return to the main menu..."
    read -r
    exit 1
}

# Display banner
display_banner "Setting Up Docker"

# Stop and disable Docker services if running
echo "Stopping Docker services..."
sudo systemctl stop docker.service docker.socket || echo "Docker services were not running."

# Remove existing Docker packages
echo "Removing existing Docker packages..."
sudo apt-get purge -y docker-engine docker docker.io docker-ce docker-ce-cli docker-ce-rootless-extras || { display_error "Failed to remove Docker packages"; }
sudo apt-get autoremove -y --purge || { display_error "Failed to remove unnecessary packages"; }
sudo rm -rf /var/lib/docker /etc/docker
sudo rm /etc/apparmor.d/docker
sudo groupdel docker || echo "Docker group does not exist, continuing..."
sudo rm -rf /var/run/docker.sock

# Detect Linux distribution and version
. /etc/os-release
DISTRO=$ID
VERSION=$VERSION_ID

# Update package list and install dependencies
echo "Installing Dependencies..."
sudo apt-get update -y || { display_error "Failed to update package list"; }
sudo apt-get install -y curl git wget uidmap npm || { display_error "Failed to install necessary packages"; }

# Install Docker in rootless mode
echo "Installing Docker in Rootless Mode..."
curl -fsSL https://get.docker.com/rootless | sh || { display_error "Failed to install Docker in rootless mode"; }

# Add Docker binaries to the user's PATH
echo 'export PATH=$HOME/bin:$PATH' >> "$HOME/.bashrc"
export PATH=$HOME/bin:$PATH

# Install Docker Desktop (based on detected distribution)
if [[ "$DISTRO" == "ubuntu" || "$DISTRO" == "debian" ]]; then
    echo "Installing Docker Desktop..."
    sudo apt-get install -y docker-desktop || { display_error "Failed to install Docker Desktop"; }
else
    display_error "Unsupported distribution. Please install Docker Desktop manually."
fi

# Create Docker directory structure
echo "Creating Docker Directory Structure..."
mkdir -p "$HOME/docker/laravel" "$HOME/docker/wordpress" "$HOME/docker/drupal" "$HOME/docker/other" || { display_error "Failed to create Docker directory structure"; }

# Create Dockerfiles and docker-compose.yml files for each platform

# Laravel
cat <<EOL > "$HOME/docker/laravel/Dockerfile"
FROM php:${PHP_VERSION}-fpm
RUN docker-php-ext-install pdo pdo_mysql
WORKDIR /var/www/html
EOL

cat <<EOL > "$HOME/docker/laravel/docker-compose.yml"
version: '3.8'
services:
  app:
    build: .
    volumes:
      - ./src:/var/www/html
    environment:
      - PHP_VERSION=${PHP_VERSION}
    ports:
      - "8000:80"
    networks:
      - laravel-net
  nginx:
    image: ${NGINX_VERSION}
    ports:
      - "8080:80"
    volumes:
      - ./src:/var/www/html
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf
    networks:
      - laravel-net
  db:
    image: mysql:${MYSQL_VERSION}
    volumes:
      - db_data:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD=${DB_ROOT_PASSWORD}
      MYSQL_DATABASE=laravel
      MYSQL_USER=laravel
      MYSQL_PASSWORD=${DB_USER_PASSWORD}
    networks:
      - laravel-net
volumes:
  db_data:
networks:
  laravel-net:
EOL

# WordPress
cat <<EOL > "$HOME/docker/wordpress/Dockerfile"
FROM wordpress:${WORDPRESS_VERSION}
EOL

cat <<EOL > "$HOME/docker/wordpress/docker-compose.yml"
version: '3.8'
services:
  wordpress:
    build: .
    ports:
      - "8080:80"
    volumes:
      - ./src/wp-content:/var/www/html/wp-content
    networks:
      - wordpress-net
  nginx:
    image: ${NGINX_VERSION}
    ports:
      - "8081:80"
    volumes:
      - ./src:/var/www/html
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf
    networks:
      - wordpress-net
  db:
    image: mysql:${MYSQL_VERSION}
    volumes:
      - db_data:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD=${DB_ROOT_PASSWORD}
      MYSQL_DATABASE=wordpress
      MYSQL_USER=wordpress
      MYSQL_PASSWORD=${DB_USER_PASSWORD}
    networks:
      - wordpress-net
volumes:
  db_data:
networks:
  wordpress-net:
EOL

# Drupal
cat <<EOL > "$HOME/docker/drupal/Dockerfile"
FROM drupal:${DRUPAL_VERSION}
EOL

cat <<EOL > "$HOME/docker/drupal/docker-compose.yml"
version: '3.8'
services:
  drupal:
    build: .
    ports:
      - "8080:80"
    volumes:
      - ./src:/var/www/html/modules/custom
    networks:
      - drupal-net
  nginx:
    image: ${NGINX_VERSION}
    ports:
      - "8082:80"
    volumes:
      - ./src:/var/www/html
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf
    networks:
      - drupal-net
  db:
    image: mysql:${MYSQL_VERSION}
    volumes:
      - db_data:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD=${DB_ROOT_PASSWORD}
      MYSQL_DATABASE=drupal
      MYSQL_USER=drupal
      MYSQL_PASSWORD=${DB_USER_PASSWORD}
    networks:
      - drupal-net
volumes:
  db_data:
networks:
  drupal-net:
EOL

# Other platform
cat <<EOL > "$HOME/docker/other/Dockerfile"
# Base Dockerfile for other platforms. Modify as needed.
FROM ubuntu:latest
RUN apt-get update && apt-get install -y \
    php \
    nginx \
    mysql-client
WORKDIR /var/www/html
EOL

cat <<EOL > "$HOME/docker/other/docker-compose.yml"
version: '3.8'
services:
  app:
    build: .
    volumes:
      - ./src:/var/www/html
    ports:
      - "8083:80"
    networks:
      - other-net
  nginx:
    image: ${NGINX_VERSION}
    ports:
      - "8084:80"
    volumes:
      - ./src:/var/www/html
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf
    networks:
      - other-net
  db:
    image: mysql:${MYSQL_VERSION}
    volumes:
      - db_data:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD=${DB_ROOT_PASSWORD}
      MYSQL_DATABASE=other
      MYSQL_USER=other
      MYSQL_PASSWORD=${DB_USER_PASSWORD}
    networks:
      - other-net
volumes:
  db_data:
networks:
  other-net:
EOL

# Create the NGINX configuration file for default site
mkdir -p "$HOME/docker/nginx" || { display_error "Failed to create NGINX configuration directory"; }
cat <<EOL > "$HOME/docker/nginx/default.conf"
server {
    listen 80;
    server_name localhost;
    root /var/www/html;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOL

echo ""
echo "Build Docker images for Laravel, WordPress, Drupal with this command:"
echo "cd ~/docker/laravel && docker build -t laravel-base ."
echo ""

# Output success message
echo "Success! Docker installed and the base environments have been set up."
echo ""
