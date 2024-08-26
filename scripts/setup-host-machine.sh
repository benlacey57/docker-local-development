#!/bin/bash

# Set PHP version and extensions
PHP_VERSION=8.2.0
PHP_EXTENSIONS="curl dom mbstring xml zip intl gd"

# Function to display a banner
display_banner() {
    clear
    echo "======================================="
    echo "   $1"
    echo "======================================="
}

# Display the banner for the start of the installation
display_banner "Starting Setup"

# Update package list and install dependencies
echo "Updating package list and installing dependencies..."
sudo apt-get update -y
sudo apt-get install -y git curl libssl-dev libcurl4-openssl-dev libxml2-dev libsqlite3-dev libonig-dev autoconf build-essential libreadline-dev libzip-dev zlib1g-dev libicu-dev libfreetype6-dev libjpeg-dev libpng-dev nala

# Install phpenv
echo "Installing PHP Env (Multi-Version Support)..."
curl -L https://raw.githubusercontent.com/phpenv/phpenv-installer/master/bin/phpenv-installer | bash

# Install php-build plugin for phpenv
echo "Installing php-build plugin for PHP Env..."
git clone https://github.com/phpenv/php-build.git "$HOME/.phpenv/plugins/php-build"

# Install PHP 8.2
display_banner "Installing PHP v$PHP_VERSION"
phpenv install "$PHP_VERSION"
phpenv global "$PHP_VERSION"

# Verify PHP installation
php -v

# Install Composer
display_banner "Installing Composer..."
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

# Install common PHP extensions for web development and CLI usage
display_banner "Installing PHP Extensions"
for extension in $PHP_EXTENSIONS; do
  phpenv exec pecl install "$extension"
done

# Xdebug installation and setup
display_banner "Installing XDebug..."
sudo apt install -y php-xdebug || { echo "Xdebug installation failed"; exit 1; }
echo "zend_extension=$(find /usr/lib/php/ -name xdebug.so)" | sudo tee -a "/etc/php/$PHP_VERSION/cli/php.ini"
echo "xdebug.mode=debug" | sudo tee -a "/etc/php/$PHP_VERSION/cli/php.ini"
echo "xdebug.start_with_request=yes" | sudo tee -a "/etc/php/$PHP_VERSION/cli/php.ini"
echo "xdebug.client_port=9003" | sudo tee -a "/etc/php/$PHP_VERSION/cli/php.ini"
echo "xdebug.client_host=host.docker.internal" | sudo tee -a "/etc/php/$PHP_VERSION/cli/php.ini"

# PHP CodeSniffer and PHP Mess Detector
display_banner "Installing PHP CodeSniffer and PHP Mess Detector..."
composer global require "squizlabs/php_codesniffer=*" --no-interaction
composer global require "phpmd/phpmd" --no-interaction

# Install Conky
display_banner "Installing Conky..."
sudo apt install -y conky

# Install Python
display_banner "Installing Python and Pip Package Manager..."
sudo apt install -y python3 python3-pip

# Install Node Version Manager (NVM) and Node.js
display_banner "Installing Node and Node Version Manager..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash || { echo "NVM installation failed"; exit 1; }
NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
export NVM_DIR
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install node || { echo "Node.js installation failed"; exit 1; }
nvm use node

# Global NPM packages
display_banner "Installing Global NPM Packages..."
npm install -g @wordpress/scripts stylelint stylelint-config-standard eslint eslint-plugin-react eslint-plugin-vue laravel-mix nodemon sass jest live-server http-server dotenv webpack gulp prettier browsersync phpcs phpcbf phpmd || { echo "NPM package installation failed"; exit 1; }

# Install Web Browsers
display_banner "Installing Web Browsers..."
sudo apt install -y google-chrome-stable firefox opera || { echo "Browser installation failed"; exit 1; }

# Install SQLite and Database Reader
display_banner "Installing SQLite and Database Reader..."
sudo apt install -y sqlite3 sqlitebrowser || { echo "SQLite installation failed"; exit 1; }

# Install Oh My Zsh and Powerlevel10k
display_banner "Installing Oh My ZSH and Powerlevel 10k..."
sudo apt install -y zsh || { echo "Zsh installation failed"; exit 1; }
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || { echo "Oh My Zsh installation failed"; exit 1; }
chsh -s "$(which zsh)"

# Install Powerlevel10k theme
display_banner "Installing Powerlevel10k Theme..."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/powerlevel10k"
echo "source $HOME/powerlevel10k/powerlevel10k.zsh-theme" >> "$HOME/.zshrc"

# Copy Powerlevel10k config file from dotfiles
cp "$HOME/dotfiles/.p10k.zsh" "$HOME/"

# Apply default Powerlevel10k config for all users
sudo cp "$HOME/dotfiles/.p10k.zsh" /etc/skel/

# Replace existing files with those in dotfiles
display_banner "Copying Dotfiles to Home Directory..."
cp -r "$HOME/dotfiles/." "$HOME/"

# SSH Key Setup
display_banner "Setting Up SSH Key..."
ssh-keygen -t rsa -b 4096 -C "$SSH_KEY_COMMENT" -N "" -f "$HOME/.ssh/id_rsa"
eval "$(ssh-agent -s)"
ssh-add "$HOME/.ssh/id_rsa"

# Configure SSH to use key on startup
echo "Configuring SSH Agent to Load Key on Startup..."
echo "eval \"$(ssh-agent -s)\"" >> "$HOME/.bashrc"
echo "ssh-add $HOME/.ssh/id_rsa" >> "$HOME/.bashrc"
echo "eval \"$(ssh-agent -s)\"" >> "$HOME/.zshrc"
echo "ssh-add $HOME/.ssh/id_rsa" >> "$HOME/.zshrc"

# Add phpenv to bash profile
echo "Adding PHPEnv to Bash Profile..."
echo "export PATH=\"$HOME/.phpenv/bin:\$PATH\"" >> "$HOME/.bashrc"
echo "eval \"\$(phpenv init -)\"" >> "$HOME/.bashrc"
source "$HOME/.bashrc"
