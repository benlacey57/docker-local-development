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

# Update the package list and install prerequisites
echo "Updating package list and installing prerequisites..."
sudo apt-get update -y || { display_error "Failed to update package list"; }
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common || { display_error "Failed to install prerequisites"; }

# Add Docker’s official GPG key and set up the stable repository
echo "Adding Docker's official GPG key and repository..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg || { display_error "Failed to add Docker GPG key"; }
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null || { display_error "Failed to add Docker repository"; }

# Update the package list again and install Docker Engine, CLI, and Containerd
echo "Installing Docker Engine, CLI, and Containerd..."
sudo apt-get update -y || { display_error "Failed to update package list after adding Docker repository"; }
sudo apt-get install -y docker-ce docker-ce-cli containerd.io || { display_error "Failed to install Docker"; }

# Enable and start the Docker service
echo "Enabling and starting Docker service..."
sudo systemctl enable docker || { display_error "Failed to enable Docker service"; }
sudo systemctl start docker || { display_error "Failed to start Docker service"; }

# Verify Docker installation
if ! command -v docker &> /dev/null; then
    display_error "Docker installation failed."
else
    echo "Docker installed successfully."
fi

# Install Docker Desktop (for Ubuntu)
echo "Installing Docker Desktop..."
sudo apt-get install -y docker-desktop || { display_error "Failed to install Docker Desktop"; }

# Create Docker directory structure
echo "Creating Docker Directory Structure..."
mkdir -p "$HOME/docker/platforms/laravel" "$HOME/docker/platforms/wordpress" "$HOME/docker/platforms/drupal" "$HOME/docker/config" || { display_error "Failed to create Docker directory structure"; }

# Create the NGINX configuration file
cat <<EOL > "$HOME/docker/config/nginx.conf"
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

# Create the PHP configuration file
cat <<EOL > "$HOME/docker/config/php.ini"
[PHP]
error_reporting = E_ALL
display_errors = On
display_startup_errors = On
log_errors = On
error_log = /var/log/php_errors.log

[Date]
date.timezone = UTC
EOL

# Create Dockerfiles and docker-compose.yml files for each platform

# Laravel
cat <<EOL > "$HOME/docker/platforms/laravel/Dockerfile"
FROM php:${PHP_VERSION}-fpm
RUN docker-php-ext-install pdo pdo_mysql
WORKDIR /var/www/html
EOL

cat <<EOL > "$HOME/docker/platforms/laravel/docker-compose.yml"
version: '3.8'
services:
  app:
    build: .
    volumes:
      - ./src:/var/www/html
      - ../../config/php.ini:/usr/local/etc/php/conf.d/php.ini
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
      - ../../config/nginx.conf:/etc/nginx/conf.d/default.conf
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
cat <<EOL > "$HOME/docker/platforms/wordpress/Dockerfile"
FROM wordpress:${WORDPRESS_VERSION}
EOL

cat <<EOL > "$HOME/docker/platforms/wordpress/docker-compose.yml"
version: '3.8'
services:
  wordpress:
    build: .
    ports:
      - "8080:80"
    volumes:
      - ./src/wp-content:/var/www/html/wp-content
      - ../../config/php.ini:/usr/local/etc/php/conf.d/php.ini
    networks:
      - wordpress-net
  nginx:
    image: ${NGINX_VERSION}
    ports:
      - "8081:80"
    volumes:
      - ./src:/var/www/html
      - ../../config/nginx.conf:/etc/nginx/conf.d/default.conf
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
cat <<EOL > "$HOME/docker/platforms/drupal/Dockerfile"
FROM drupal:${DRUPAL_VERSION}
EOL

cat <<EOL > "$HOME/docker/platforms/drupal/docker-compose.yml"
version: '3.8'
services:
  drupal:
    build: .
    ports:
      - "8080:80"
    volumes:
      - ./src:/var/www/html/modules/custom
      - ../../config/php.ini:/usr/local/etc/php/conf.d/php.ini
    networks:
      - drupal-net
  nginx:
    image: ${NGINX_VERSION}
    ports:
      - "8082:80"
    volumes:
      - ./src:/var/www/html
      - ../../config/nginx.conf:/etc/nginx/conf.d/default.conf
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

echo ""
echo "Build Docker images for Laravel, WordPress, Drupal with this command:"
echo "cd ~/docker/platforms/laravel && docker build -t laravel-base ."
echo ""

# Output success message
echo "Success! Docker installed and the base environments have been set up."
echo ""
