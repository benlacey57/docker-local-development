#!/bin/bash

# Function to display a banner
display_banner() {
    clear
    echo "======================================="
    echo "   $1"
    echo "======================================="
}

# Function to list available platforms based on $HOME/docker/ content
list_platforms() {
    echo "Available platforms:"
    local i=1
    for platform in $(ls -d "$HOME/docker/"*/ 2>/dev/null | grep -v "/scripts/" | xargs -n 1 basename); do
        echo "$i. $platform"
        i=$((i+1))
    done
    echo "$i. Other"
}

# Function to create a new client environment
create_environment() {
    display_banner "Create a New Client Environment"

    read -rp "Enter the client name: " client_name

    list_platforms
    read -rp "Select the platform by number: " platform_number

    # Determine the selected platform
    i=1
    for platform in $(ls -d "$HOME/docker/"*/ 2>/dev/null | grep -v "/scripts/" | xargs -n 1 basename); do
        if [ "$i" -eq "$platform_number" ]; then
            selected_platform=$platform
        fi
        i=$((i+1))
    done

    if [ "$i" -eq "$platform_number" ]; then
        selected_platform="Other"
    fi

    # Handle the "Other" option if selected
    if [ "$selected_platform" == "Other" ]; then
        display_banner "Create Dockerfile for Other Platform"
        read -rp "Enter the platform name: " selected_platform
        blueprint_dir="$HOME/docker/$selected_platform"

        # Create the directory for the new blueprint if it doesn't exist
        mkdir -p "$blueprint_dir"

        # Use the create-dockerfile.sh script to generate the Dockerfile and docker-compose.yml
        ./create-dockerfile.sh "$selected_platform"

        # Add the new platform to the list of available platforms
        echo "$selected_platform" >> "$HOME/docker/platforms.list"
    fi

    display_banner "Creating Client Environment"

    # Create client directory structure
    client_dir="$HOME/sites/clients/${client_name}"
    mkdir -p "${client_dir}/src"
    mkdir -p "${client_dir}/logs"
    mkdir -p "${client_dir}/nginx"
    mkdir -p "${client_dir}/certs"

    # Create Dockerfile override for the client
    cat <<EOL > "${client_dir}/Dockerfile"
FROM ${selected_platform}:latest

WORKDIR /var/www/html

COPY ./src /var/www/html

# Additional configuration can be added here
EOL

    # Create docker-compose.yml override for the client
    cp "$HOME/docker/${selected_platform}/docker-compose.yml" "${client_dir}/docker-compose.yml"

    # Create NGINX config override for the client
    cp "$HOME/docker/nginx/default.conf" "${client_dir}/nginx/default.conf"

    # Merge client-specific configuration files with defaults if they exist
    if [ -f "${client_dir}/src/wp-config.php" ] || [ -f "${client_dir}/src/configuration.php" ]; then
        ./merge-configs.sh "${client_dir}"
    fi

    read -rp "Enter the PHP version (default: 8.2): " php_version
    php_version=${php_version:-8.2}

    echo "Select the database type:"
    echo "1. MySQL"
    echo "2. PostgreSQL"
    read -rp "Enter the database choice [1-2]: " db_choice

    case $db_choice in
        1) db_type="mysql:latest" ;;
        2) db_type="postgres:latest" ;;
        *) echo "Invalid choice, defaulting to MySQL"; db_type="mysql:latest" ;;
    esac

    # Create a docker-compose.override.yml for custom settings
    cat <<EOL > "${client_dir}/docker-compose.override.yml"
version: '3.8'
services:
  app:
    environment:
      - PHP_VERSION=${php_version}
  db:
    image: ${db_type}
EOL

    # Run the PHP security checks setup script if the platform is PHP-based
    if [[ "$selected_platform" == "laravel" || "$selected_platform" == "wordpress" || "$selected_platform" == "drupal" || "$selected_platform" == "Other" ]]; then
        ./setup-php-security-checks.sh "${client_dir}"
    fi

    echo "Client environment has been set up at ${client_dir}."
    read -rp "Would you like to start the environment now? (y/n): " start_now
    
    if [ "$start_now" == "y" ]; then
        cd "${client_dir}" || exit
        docker-compose up -d
        echo "Environment started."
    fi
}

# Main script execution
create_environment
