FROM php:8.4-fpm

# Update the system
RUN apt update -y && apt upgrade -y
# Install necessary packages
RUN apt install -y \
    build-essential \
    libonig-dev \
    zlib1g-dev \
    libpng-dev \
    libicu-dev \
    libzip-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libwebp-dev \
    libavif-dev \
    libxpm-dev \
    nano \
    procps \
    git \
    wget

# Install extensions
RUN docker-php-ext-install -j$(nproc) mbstring && \
    docker-php-ext-install -j$(nproc) intl && \
    docker-php-ext-install -j$(nproc) pdo_mysql && \
    docker-php-ext-install -j$(nproc) zip && \
    pecl install zstd && pecl install redis && \
    docker-php-ext-enable zstd && docker-php-ext-enable redis

# Install GD module
RUN docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg=/usr/local/lib --with-webp --with-xpm --with-avif && \
    docker-php-ext-install -j$(nproc) gd

# Install EXIF module
RUN docker-php-ext-configure exif --enable-exif && \
    docker-php-ext-install -j$(nproc) exif

# Install OPCache
RUN docker-php-ext-configure opcache --enable-opcache && \
    docker-php-ext-install -j$(nproc) opcache

# Add extra configuration options
RUN echo 'memory_limit = 1024M' >> /usr/local/etc/php/conf.d/docker-php-memlimit.ini && \
    echo 'opcache.memory_consumption = 256' >> /usr/local/etc/php/conf.d/docker-php-opcache.ini && \
    echo 'max_execution_time = 180' >> /usr/local/etc/php/conf.d/docker-php-exec-time.ini && \
    echo 'pm = static' >> /usr/local/etc/php-fpm.d/zz-docker.conf && \
    echo 'pm.max_children = 8' >> /usr/local/etc/php-fpm.d/zz-docker.conf && \
    echo 'pm.max_requests = 500' >> /usr/local/etc/php-fpm.d/zz-docker.conf && \
    echo 'listen.backlog = 256' >> /usr/local/etc/php-fpm.d/zz-docker.conf;

# OPCache tuning
RUN echo 'opcache.enable_file_override=1' >> /usr/local/etc/php/conf.d/docker-php-opcache.ini && \
    echo 'opcache.max_accelerated_files=65407' >> /usr/local/etc/php/conf.d/docker-php-opcache.ini && \
    echo 'opcache.validate_timestamps=0' >> /usr/local/etc/php/conf.d/docker-php-opcache.ini && \
    echo 'opcache.interned_strings_buffer=20' >> /usr/local/etc/php/conf.d/docker-php-opcache.ini;

# Performance optimizations
RUN echo 'zend.assertions=-1' >> /usr/local/etc/php/conf.d/docker-php-sw-opts.ini && \
    echo 'zend.detect_unicode=0' >> /usr/local/etc/php/conf.d/docker-php-sw-opts.ini && \
    echo 'realpath_cache_ttl=3600' >> /usr/local/etc/php/conf.d/docker-php-sw-opts.ini;

# Copy the entrypoint script
COPY ./entrypoint-php.sh /entrypoint.sh
# Make it executable
RUN chmod +x /entrypoint.sh

STOPSIGNAL SIGTERM

# Run php-fpm
CMD ["/entrypoint.sh"]