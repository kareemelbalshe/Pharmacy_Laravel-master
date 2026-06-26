# ==============================================================================
# STAGE 1: Build the frontend assets (Vite/NPM)
# ==============================================================================
FROM node:20-alpine AS frontend-builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# ==============================================================================
# STAGE 2: Build the backend dependencies (Composer)
# ==============================================================================
FROM composer:latest AS vendor-builder
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install \
    --ignore-platform-reqs \
    --no-interaction \
    --no-plugins \
    --no-dev \
    --no-scripts \
    --no-autoloader \
    --prefer-dist



# ==============================================================================
# STAGE 3: Final Production Image
# ==============================================================================
FROM php:8.2-apache AS runner

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    zip \
    unzip \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions using docker-php-extension-installer
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions && \
    install-php-extensions pdo_mysql mbstring zip exif pcntl bcmath gd intl

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Increase PHP execution time for production/docker
RUN echo "max_execution_time = 300" >> /usr/local/etc/php/conf.d/docker-php-max-ex-time.ini

# Set working directory
WORKDIR /var/www/html

# Copy the entire source code (excluding ignored files)
COPY . .

# Copy built frontend assets from STAGE 1
COPY --from=frontend-builder /app/public/build ./public/build

# Copy vendor dependencies from STAGE 2
COPY --from=vendor-builder /app/vendor ./vendor

# Copy Composer binary from official image
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Generate optimized autoloader
RUN composer dump-autoload --optimize --no-dev

# Clear Laravel caches
RUN php artisan config:clear && \
    php artisan route:clear && \
    php artisan view:clear

# Set permissions
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Update Apache config to point to public/
RUN sed -i 's|/var/www/html|/var/www/html/public|g' /etc/apache2/sites-available/000-default.conf

# Expose port 80
EXPOSE 80

CMD ["apache2-foreground"]

