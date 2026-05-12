FROM php:8.4-apache

# Install basic system dependencies
RUN apt-get update && apt-get install -y \
    zip \
    unzip \
    git \
    curl \
    gnupg \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

RUN chmod +x /usr/local/bin/install-php-extensions && \
    install-php-extensions pdo_mysql mbstring zip exif pcntl bcmath gd intl

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Increase PHP execution time for production/docker
RUN echo "max_execution_time = 300" >> /usr/local/etc/php/conf.d/docker-php-max-ex-time.ini

# Set working directory
WORKDIR /var/www/html

# Copy only dependency files first to leverage Docker cache
COPY composer.json composer.lock ./
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-dev --no-scripts --no-autoloader

COPY package.json package-lock.json ./
RUN npm install

# Copy the rest of the application
COPY . .

# Finish composer installation
RUN composer dump-autoload --optimize

# Build frontend assets (Vite/Mix)
RUN npm run build

# Set permissions
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Update Apache config to point to public/
RUN sed -i 's|/var/www/html|/var/www/html/public|g' /etc/apache2/sites-available/000-default.conf

# Expose port 80
EXPOSE 80

CMD ["apache2-foreground"]
