FROM wordpress:latest

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Set the working directory
WORKDIR /var/www/html

# Install additional PHP extensions if needed
RUN docker-php-ext-install ${PHP_EXTENSIONS} mysqli

# Copy wp-config-default.php to container (if you have default configurations)
COPY wp-config-default.php /var/www/html/wp-config-default.php

# Make sure permissions are correct
RUN chown -R www-data:www-data /var/www/html
