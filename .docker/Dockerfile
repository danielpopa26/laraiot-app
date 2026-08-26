FROM php:8.3-fpm-alpine

# Instalare extensii necesare + Node.js si NPM
RUN apk add --no-cache \
    bash \
    git \
    curl \
    nodejs \
    npm \
    libpng-dev \
    libzip-dev \
    zip \
    unzip \
    linux-headers \
    $PHPIZE_DEPS \
    && docker-php-ext-install pdo_mysql pcntl sockets bcmath opcache zip

# Configurare Git safe directory globala pentru containere
RUN git config --system --add safe.directory '*'

# Instalare Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www