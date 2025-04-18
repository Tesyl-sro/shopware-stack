#!/bin/bash

echo "Setting /app/public ownership..."
chgrp -R 33 /app/public
chown -hR 33:33 /app/public

echo "Setting permissions for /app/public/var..."
chmod a+w /app/public/var/*

echo "Starting PHP-FPM..."
php-fpm