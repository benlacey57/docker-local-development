#!/bin/bash

# Function to display a banner
display_banner() {
    clear
    echo "======================================="
    echo "   Setting Up PHP Security Checks"
    echo "======================================="
}

# Function to setup PHP security checks in the specified client directory
setup_php_security_checks() {
    client_dir="$1"

    display_banner

    # Check if the client directory is provided
    if [ -z "$client_dir" ]; then
        echo "Error: No client directory specified."
        exit 1
    fi

    # Make sure the client directory exists
    if [ ! -d "${client_dir}/src" ]; then
        echo "Error: Client src directory does not exist."
        exit 1
    fi

    # Navigate to the client directory
    cd "${client_dir}/src" || exit

    # Install PHP_CodeSniffer
    composer require --dev squizlabs/php_codesniffer

    # Install PHPStan
    composer require --dev phpstan/phpstan

    # Create default configuration files if they don't exist
    if [ ! -f "phpcs.xml" ]; then
        cat <<EOL > phpcs.xml
<?xml version="1.0"?>
<ruleset name="Custom Rules">
    <description>Custom PHP_CodeSniffer rules</description>
    <file>./</file>
    <rule ref="PSR12"/>
</ruleset>
EOL
    fi

    if [ ! -f "phpstan.neon" ]; then
        cat <<EOL > phpstan.neon
includes:
    - vendor/phpstan/phpstan/conf/bleedingEdge.neon

parameters:
    level: max
    paths:
        - .
EOL
    fi

    echo "PHP security checks have been set up in ${client_dir}."
}

# Main script execution
setup_php_security_checks "$1"
