# Testing image used for GitLab CI
FROM drupalci/php-8.4-ubuntu-apache:production

# Install Playwright with dependencies
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
