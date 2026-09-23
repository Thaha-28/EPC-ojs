FROM php:8.2-apache

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    libxml2-dev \
    libonig-dev \
    libcurl4-openssl-dev \
    libicu-dev \
    libxslt1-dev \
    libmagickwand-dev \
    ca-certificates \
    unzip \
    git \
    curl \
    cron \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd mysqli pdo_mysql zip xml mbstring curl intl bcmath xsl soap ftp \
    && a2enmod rewrite headers expires \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /var/www/html

# Copy OJS files
COPY . /var/www/html/

# Install Composer and PHP dependencies for lib/pkp
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
RUN composer install --working-dir=/var/www/html/lib/pkp --no-dev --no-interaction --optimize-autoloader --no-scripts && \
    ls -lh /var/www/html/lib/pkp/lib/vendor/autoload.php && \
    echo "vendor installed OK"

# Create required directories
RUN mkdir -p /var/www/ojs-files \
    && mkdir -p /var/www/html/cache \
    && mkdir -p /var/www/html/public \
    && chown -R www-data:www-data /var/www/html \
    && chown -R www-data:www-data /var/www/ojs-files \
    && chmod -R 755 /var/www/html/cache /var/www/html/public \
    && chmod -R 775 /var/www/ojs-files

# Apache config for OJS (allow .htaccess, handle Authorization header for API)
RUN echo '<Directory /var/www/html>\n\
    Options Indexes FollowSymLinks\n\
    AllowOverride All\n\
    Require all granted\n\
    CGIPassAuth On\n\
</Directory>\n\
SetEnvIf Authorization "(.*)" HTTP_AUTHORIZATION=$1' > /etc/apache2/conf-available/ojs.conf \
    && a2enconf ojs

# Apache MPM fix - php:8.2-apache ships with mpm_event active; mod_php requires
# exactly one MPM (prefork). Remove ALL mpm symlinks first, then enable only prefork.
# Kept as the last Apache-mods layer so nothing re-enables event/worker afterwards.
RUN rm -f /etc/apache2/mods-enabled/mpm_event.load /etc/apache2/mods-enabled/mpm_event.conf /etc/apache2/mods-enabled/mpm_worker.load /etc/apache2/mods-enabled/mpm_worker.conf /etc/apache2/mods-enabled/mpm_prefork.load /etc/apache2/mods-enabled/mpm_prefork.conf && a2enmod mpm_prefork && apache2ctl -M 2>&1 | grep mpm || true

# Use production php.ini
RUN cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini \
    && sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 32M/' /usr/local/etc/php/php.ini \
    && sed -i 's/post_max_size = 8M/post_max_size = 32M/' /usr/local/etc/php/php.ini \
    && sed -i 's/max_execution_time = 30/max_execution_time = 120/' /usr/local/etc/php/php.ini \
    && sed -i 's/memory_limit = 128M/memory_limit = 256M/' /usr/local/etc/php/php.ini

# Copy entrypoint
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 80

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
