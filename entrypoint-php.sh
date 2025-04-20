#!/bin/bash

function exit_container_SIGTERM(){
  echo "Caught SIGTERM"
  exit 0
}
trap exit_container_SIGTERM SIGTERM

echo "Setting /app/public ownership..."
chgrp -R 33 /app/public
chown -hR 33:33 /app/public

echo "Setting permissions for /app/public/var..."
chmod a+w /app/public/var/*

echo "Starting PHP-FPM..."
php-fpm -F & wait