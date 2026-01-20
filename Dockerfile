# Multi-stage build for Node.js
FROM node:24-slim AS node-stage

# Testing image used for GitLab CI
FROM drupalci/php-8.4-ubuntu-apache:production AS base

# Copy Node.js binaries and modules from the official Node.js image
COPY --from=node-stage /usr/local/bin/node /usr/local/bin/
COPY --from=node-stage /usr/local/lib/node_modules /usr/local/lib/node_modules
# Create symlinks for npm and npx
RUN ln -sf /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm && \
    ln -sf /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

# Install system packages and clean up in a single layer
RUN apt-get update && apt-get install -y --no-install-recommends \
    libsodium-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libicu-dev \
    libjpeg62-turbo-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libzip-dev \
    libonig-dev \
    libxml2-dev \
    curl \
    jq \
    unzip \
    ca-certificates \
    sudo \
    git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
               /tmp/* \
               /var/tmp/* \
               /usr/share/doc/* \
               /usr/share/man/*

# Configure GD with jpeg and freetype support
RUN docker-php-ext-configure gd --with-freetype --with-jpeg

# Install PHP extensions required by Drupal
RUN docker-php-ext-install -j$(nproc) \
    sodium \
    pdo \
    pdo_mysql \
    mysqli \
    gd \
    opcache \
    zip \
    mbstring \
    xml \
    dom \
    simplexml

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configure Apache and PHP in a single layer
RUN echo "memory_limit = -1" > /usr/local/etc/php/conf.d/cli-memory.ini && \
    echo "memory_limit = 512M" > /usr/local/etc/php/conf.d/apache-memory.ini

# Install Playwright with dependencies (cache-busted for latest browsers)
RUN set -eux; \
    npm install @playwright/test @shoelace-style/shoelace && \
    mkdir -p /var/www/pw-browsers && \
    date > /tmp/cache-bust && \
    PLAYWRIGHT_BROWSERS_PATH=/var/www/pw-browsers npx playwright install --with-deps && \
    # Clean up in same layer to reduce size (including Playwright cache!)
    rm -f /tmp/cache-bust && \
    rm -rf /tmp/* \
           /var/tmp/* \
           /var/lib/apt/lists/* \
           ~/.npm \
           /root/.cache \
           /usr/share/doc/* \
           /usr/share/man/* \
           /usr/share/locale/* \
           /usr/share/pixmaps/* \
           /usr/share/icons/hicolor/*/apps/* \
           /var/cache/debconf/*

WORKDIR /var/www/html
