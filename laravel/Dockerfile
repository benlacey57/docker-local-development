FROM php:${PHP_VERSION}-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip

# Install PHP extensions
RUN docker-php-ext-install ${PHP_EXTENSIONS} pdo_mysql mbstring exif pcntl bcmath gd

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Install Laravel
RUN composer global require laravel/installer

# Ensure ~/.composer/vendor/bin is in PATH
ENV PATH $PATH:/root/.composer/vendor/bin

# Install PHPUnit and Pest
RUN composer require --dev phpunit/phpunit pestphp/pest

# Copy application files
COPY . /var/www/html

# Set correct permissions
RUN chown -R www-data:www-data /var/www/html
