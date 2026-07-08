#!/bin/bash

set -e

function exit_container_SIGTERM(){
  echo "Caught SIGTERM"
  exit 0
}
trap exit_container_SIGTERM SIGTERM

echo "Setting /app/public ownership..."
chgrp -R 33 /app/public
chown -hR 33:33 /app/public

if [ -d "/app/public/var" ]; then
    echo "Directory /app/public/var exists, setting permissions..."
    chmod a+w /app/public/var/*
else
    echo "Directory /app/public/var does not exist"
fi

if [ -z "$(find /app/public -mindepth 1 -maxdepth 1)" ]; then
  echo "Application directory is empty, downloading Shopware installer..."
  wget https://github.com/shopware/web-recovery/releases/latest/download/shopware-installer.phar.php -O /app/public/shopware-installer.phar.php --no-verbose
else
  echo "Application directory is not empty, not downloading Shopware installer"
fi

echo "Starting PHP-FPM..."
php-fpm -F & wait