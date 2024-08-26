#!/bin/bash

# Function to display a banner
display_banner() {
    clear
    echo "======================================="
    echo "   $1"
    echo "======================================="
}

# Main menu function
function main_menu() {
    display_banner "Main Menu"

    echo "Select an option:"
    echo "1. Install dependencies (setup host machine)"
    echo "2. Install and setup Docker"
    echo "3. Create local website"
    echo "4. Delete local website"
    echo "5. Generate SSL certificate"
    echo "6. Delete SSL certificate"
    echo "7. Archive website"
    echo "8. Exit"

    read -rp "Enter your choice [1-8]: " choice
    case $choice in
        1) install_dependencies ;;
        2) install_and_setup_docker ;;
        3) create_local_website ;;
        4) delete_local_website ;;
        5) generate_ssl_certificate ;;
        6) delete_ssl_certificate ;;
        7) archive_website ;;
        8) exit 0 ;;
        *) echo "Invalid choice!" && main_menu ;;
    esac
}

# Function to install dependencies
function install_dependencies() {
    display_banner "Install Dependencies"
    ./setup-host-machine.sh
    main_menu
}

# Function to install and setup Docker
function install_and_setup_docker() {
    display_banner "Install and Setup Docker"
    ./setup-docker.sh
    
    # main_menu
}

# Function to create a local website
function create_local_website() {
    display_banner "Create Local Website"
    ./create-docker-env.sh
    main_menu
}

# Function to delete a local website
function delete_local_website() {
    display_banner "Delete Local Website"
    read -rp "Enter the client name to delete: " client_name
    client_dir="$HOME/sites/clients/${client_name}"

    if [ -d "${client_dir}" ]; then
        echo "Deleting the local website and its Docker environment..."
        rm -rf "${client_dir}"
        echo "Website ${client_name} deleted successfully."
    else
        echo "Error: The website ${client_name} does not exist."
    fi

    main_menu
}

# Function to generate SSL certificate
function generate_ssl_certificate() {
    display_banner "Generate SSL Certificate"
    read -rp "Enter the domain name for SSL certificate: " domain_name
    read -rp "Enter the client name: " client_name
    cert_dir="$HOME/sites/clients/${client_name}/certs"

    if [ ! -d "${cert_dir}" ]; then
        mkdir -p "${cert_dir}"
        openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
            -subj "/C=${SSL_COUNTRY_NAME}/ST=${SSL_STATE_OR_PROVINCE_NAME}/L=${SSL_LOCALITY_NAME}/O=${SSL_ORGANIZATION_NAME}/CN=${domain_name}" \
            -keyout "${cert_dir}/nginx.key" -out "${cert_dir}/nginx.crt"
        echo "SSL certificate generated for ${domain_name}."
    else
        echo "Error: SSL certificate for ${domain_name} already exists."
    fi

    main_menu
}

# Function to delete SSL certificate
function delete_ssl_certificate() {
    display_banner "Delete SSL Certificate"
    read -rp "Enter the domain name for SSL certificate to delete: " domain_name
    read -rp "Enter the client name: " client_name
    cert_dir="$HOME/sites/clients/${client_name}/certs"

    if [ -d "${cert_dir}" ]; then
        rm -rf "${cert_dir}"
        echo "SSL certificate for ${domain_name} deleted successfully."
    else
        echo "Error: SSL certificate for ${domain_name} does not exist."
    fi

    main_menu
}

# Function to archive a website
function archive_website() {
    display_banner "Archive Website"
    read -rp "Enter the client name to archive: " client_name
    client_dir="$HOME/sites/clients/${client_name}"
    archive_dir="$HOME/site-archives"

    if [ -d "${client_dir}" ]; then
        mkdir -p "${archive_dir}"
        tar -czf "${archive_dir}/${client_name}.tar.gz" -C "${client_dir}" .
        echo "Website ${client_name} archived successfully."
    else
        echo "Error: The website ${client_name} does not exist."
    fi

    main_menu
}

# Run the main menu
main_menu
