FROM php:8.2-apache

# Install PostgreSQL, MySQL, SQLite and other database drivers
RUN apt-get update && apt-get install -y \
    libpq-dev \
    libsqlite3-dev \
    curl \
    && docker-php-ext-install pdo pdo_mysql pdo_pgsql pdo_sqlite \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Enable Apache modules
RUN a2enmod rewrite headers

# Configure PHP for production
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" && \
    echo "expose_php = Off" >> "$PHP_INI_DIR/php.ini" && \
    echo "display_errors = Off" >> "$PHP_INI_DIR/php.ini" && \
    echo "log_errors = On" >> "$PHP_INI_DIR/php.ini" && \
    echo "error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT" >> "$PHP_INI_DIR/php.ini" && \
    echo "post_max_size = 50M" >> "$PHP_INI_DIR/php.ini" && \
    echo "upload_max_filesize = 50M" >> "$PHP_INI_DIR/php.ini" && \
    echo "memory_limit = 256M" >> "$PHP_INI_DIR/php.ini" && \
    echo "max_execution_time = 600" >> "$PHP_INI_DIR/php.ini" && \
    echo "max_input_time = 600" >> "$PHP_INI_DIR/php.ini"

# Configure Apache for production
RUN echo "ServerTokens Prod" >> /etc/apache2/apache2.conf && \
    echo "ServerSignature Off" >> /etc/apache2/apache2.conf && \
    echo "TraceEnable Off" >> /etc/apache2/apache2.conf

# Copy Adminer files
COPY --chown=www-data:www-data adminer/ /var/www/html/
COPY --chown=www-data:www-data externals/ /var/www/html/externals/
COPY --chown=www-data:www-data plugins/ /var/www/html/plugins/
COPY --chown=www-data:www-data designs/ /var/www/html/designs/

# Set proper permissions
RUN chmod -R 755 /var/www/html && \
    find /var/www/html -type f -exec chmod 644 {} \;

# Configure Apache to listen on port 3000
RUN sed -i 's/80/3000/g' /etc/apache2/sites-available/000-default.conf && \
    sed -i 's/80/3000/g' /etc/apache2/ports.conf

# Security headers
RUN echo '<Directory /var/www/html>' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    Header set X-Content-Type-Options "nosniff"' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    Header set X-Frame-Options "SAMEORIGIN"' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    Header set X-XSS-Protection "1; mode=block"' >> /etc/apache2/sites-available/000-default.conf && \
    echo '</Directory>' >> /etc/apache2/sites-available/000-default.conf

# Expose port 3000
EXPOSE 3000

# Run as non-root user
USER www-data

# Start Apache in foreground
CMD ["apache2-foreground"]