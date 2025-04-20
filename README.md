# Shopware 6 Docker Stack

The stack consists of:
 - PHP 8.3 (FPM) under Debian Bullseye
 - MariaDB 11.6.2 under Debian
 - Caddy (latest stable)

The [compose](./docker-compose.yml) stack will take care of building a customized PHP container image with the necessary extensions.

- [x] Pre-configured Caddy server (except domain)
  - [x] Automatic HTTP->HTTPS redirect
  - [x] Root to `www.` redirection
  - [x] Dotfiles blocked (except `.well-known/`)
- [x] Pre-configured MariaDB 11.6.2
  - [x] Secure access - inaccessible from outside, even the host itself
- [x] Pre-configured PHP 8.3.15 for Shopware
  - [x] Pre-installed modules: `mbstring`, `gd`, `intl`, `pdo_mysql`, `zip`
  - [x] Pre-configured and enabled opcache
  - [x] Increased memory limit to 1G
  - [x] Increased execution time limit to *3m*
- [x] Pre-configured background service runners for Shopware 6
  - `messenger:consume`
    - Runs as a separate container
    - Memory limit: *512MB*
  - `scheduled-task:run`
    - Runs as a separate container
    - Memory limit: *512MB*

## Getting started
Before you start, you may change the default database password in [the compose file](./docker-compose.yml). Do not attempt to create additional database users, you cannot grant permissions due to how restricted the database is. If you really want this, you'll need to at least temporarily open the MariaDB port on the container.

1. Install Docker using [these](https://docs.docker.com/engine/install/) instructions.
2. Download this repo as a zip to your server.
3. Extract the archive.
4. `cd` into the extracted folder.
    ```sh
    cd shopdock2
    ```
5. Edit the `Caddyfile` according to your domain(s). Also make sure that the **root folder** is `/app/public`.
6. Create a `site` directory:
    ```sh
    mkdir site
    ```
7. Download the Shopware installer into the `site` directory:
    ```sh
    wget https://github.com/shopware/web-recovery/releases/latest/download/shopware-installer.phar.php -O site/shopware-installer.phar.php
    ```
8. Change ownership of the `site` directory to the `www-data` user and group:
    ```sh
    chown -hR www-data:www-data site
    ```
9. Run the stack using Docker Compose, without `shopware_sched_task_runner` and `shopware_messenger_runner`.
    ```sh
    docker compose up caddy php-fpm database
    ```
    *You can add `-d` to run it in the background.*
10. Complete the initial Shopware setup at `https://[your-domain]/shopware-installer.phar.php`.
11. Shut down the server with Ctrl-C or `docker compose down` if it's running in the background.
12. Edit the `Caddyfile` so that the **root folder** is `/app/public/public`.
13. Restart the server **according to step 9**.
14. Complete the Shopware database configuration at `https://[your-domain]/installer`. Wait until the page is no longer loading after clicking `Next` during the `Configuration` step.
15. Open the admin panel by going to `/admin` (e.g. `https://example.com/admin`).
16. Complete the first-time setup.
17. Shut down the server **according to step 11**.
18. Restart the server as well as all services using `docker compose up`.

Note that during the installation, you should **not** start `shopware_sched_task_runner` and `shopware_messenger_runner`. These services should only ever be started after Shopware is **fully** installed, **including** the OOBE setup. Running these services with an incomplete installation of Shopware may brick your installation and you have to start over.

## Testing on localhost
If you want to test this stack on `localhost`, do the following:
1. Remove the HTTP->HTTPS redirect entry from `Caddyfile`:
    ```
    example.com {
      redir https://www.{host}{uri}
    }
    ```
2. Change the domain from `www.example.com` to `http://localhost`.
3. Continue as normal with the rest of the setup.

On some systems, the `www-data` user and group may not exist. In this case, use the UID `33` and GID `33` in the `chown` commands. Additionnaly, you may need to use `sudo`.

## Post-setup
Before performing these steps:
1. Make sure you're in the root directory of this repo.
2. Shut down the stack (unless stated otherwise).

**The following steps are not required, but may help improve security and performance.**

Perform the following steps to optimize Shopware for production use:
1. Disable the admin worker using a new config file.
    ```sh
    nano site/config/packages/shopware.yml
    ```

    Add the following:
    ```yml
    shopware:
        admin_worker:
            enable_admin_worker: false
    ```
2. Use `zstd` instead of `gzip` for cache and cart compression. [(Read more)](https://developer.shopware.com/docs/guides/hosting/performance/performance-tweaks.html#using-zstd-instead-of-gzip-for-compression)
   
    **You need to clear all caches and then stop the stack before doing this!**
    **Run all commands from `Reset all caches` under the `Useful commands section` first.**

    ```sh
    docker compose down
    nano site/config/packages/shopware.yml
    ```

    Add the following under `shopware`:
    ```yml
    cart:
        compress: true
        compression_method: zstd
    cache:
        cache_compression: true
        cache_compression_method: 'zstd'
    ```
3. Disable App URL external check [(Read more)](https://developer.shopware.com/docs/guides/hosting/performance/performance-tweaks.html#disable-app-url-external-check)
    
    **Make sure that `APP_URL` is set correctly, e.g. `https://mystore.com` in both `.env` and `.env.local`.**
    
    ```sh
    nano site/.env
    ```

    Add the following:
    ```
    APP_URL_CHECK_DISABLED=1
    ```

    Repeat the same for `.env.local`.

    **Restart the stack after modifying these files!**
4. **(Not recommended)** Enable OPCache preloading.
   
   _This can noticably improve loading times, but it may cause stability issues for unknown reasons._
   Add/Uncomment the following 2 lines in `Dockerfile-php`'s `OPCache tuning` section:
   
   ```dockerfile
   RUN echo 'opcache.preload = /app/public/var/cache/opcache-preload.php' >> /usr/local/etc/php/conf.d/docker-php-opcache.ini;
   RUN echo 'opcache.preload_user = www-data' >> /usr/local/etc/php/conf.d/docker-php-opcache.ini;
   ```

   **Rebuild AND restart the stack after modifying these files!**
   **Note:** This may cause stability issues, however it also noticably improves (loading) performance. If this is unstable for you, undo this change. You may also sometimes see a lot of errors from `shopware_sched_task_runner` and `shopware_messenger_runner` *during startup*. This is normal, and it should be automatically fixed after a few seconds, and if not, undo this change.

## Useful commands
 
<details>
  <summary>Clean up unused Docker containers</summary>
  
  ```sh
  docker container prune -f
  ```
</details>

<details>
  <summary>View containers and their statuses</summary>
  
  ```sh
  docker container ls -a
  ```
</details>

<details>
  <summary>Run a shell inside the PHP-FPM container</summary>
  
  ```sh
  docker exec -it php-fpm bash
  ```
</details>

<details>
  <summary>Run a shell inside the database container</summary>
  
  ```sh
  docker exec -it mariadb bash
  ```
</details>

<details>
  <summary>Use PHP CLI</summary>
  
  ```sh
  docker exec -it php-fpm php [COMMAND]
  ```

  Example:
  ```sh
  docker exec -it php-fpm php -v
  ```
</details>

<details>
  <summary>Use MariaDB CLI</summary>
  
  ```sh
  docker exec -it mariadb mariadb -u root --password=shopware -D shopware
  ```

  **Note:** If you changed the database name and/or password, you need to adjust the `-D` and `--password` arguments.
</details>

<details>
  <summary>Dump the database</summary>
  
  ```sh
  docker exec -it mariadb mariadb-dump -u root --password=shopware --skip-set-charset --default-character-set=utf8mb4 shopware > database_dump.sql
  ```

  **Note 1:** If you changed the database name and/or password, you need to adjust the `--password` argument and/or replace the database name `shopware`.
</details>

<details>
  <summary>Import an SQL file</summary>
  
  ```sh
  docker exec -i mariadb mariadb -u root --password=shopware -D shopware < [SOURCE]
  ```

  Example:
  ```sh
  docker exec -i mariadb mariadb -u root --password=shopware -D shopware < my_backup_file.sql
  ```

  **Note:** If you changed the database name and/or password, you need to adjust the `-D` and `--password` arguments.
</details>

<details>
  <summary>Use Shopware CLI</summary>
  
  ```sh
  docker exec -it php-fpm php /app/public/bin/console [COMMAND]
  ```

  Example:
  ```sh
  docker exec -it php-fpm php /app/public/bin/console about
  ```
</details>

<details>
  <summary>Run messenger tasks</summary>
  
  ```sh
  docker exec -it php-fpm php /app/public/bin/console messenger:consume async low_priority --time-limit=60 --memory-limit=512M --no-interaction --no-ansi --quiet
  ```
</details>

<details>
  <summary>Check scheduled tasks</summary>
  
  ```sh
  docker exec -it php-fpm php /app/public/bin/console scheduled-task:list
  ```
</details>

<details>
  <summary>Run scheduled tasks</summary>
  
  ```sh
  docker exec -it php-fpm php /app/public/bin/console scheduled-task:run --time-limit=60 --memory-limit=512M --no-interaction --no-ansi
  ```
</details>

<details>
  <summary>Reset all caches</summary>
  
  ```sh
  docker exec -it php-fpm php /app/public/bin/console cache:pool:clear --all
  docker exec -it php-fpm php /app/public/bin/console cache:clear
  chown -hR www-data:www-data site
  ```

  Note that if your system does **not** have the `www-data` user and group created, you can use `chown -hR 33:33 site` instead.
  Some of these commands may require root/`sudo`.
</details>

<details>
  <summary>Clean up Docker</summary>

  > __⚠️ WARNING ⚠️__
  > 
  > This will irrecoverably delete **ALL VOLUMES AND IMAGES**.
  > 
  > This will **NOT** detele your database, shopware data, Caddy configuration from this stack.
  
  **Make sure to shut down the stack before running these commands.**

  ```sh
  docker builder prune -a -f
  docker rm -vf $(docker ps -aq) # This will fail if you don't have any volumes
  docker rmi -f $(docker images -aq)
  ```
</details>

## Backing up your stack
To create a backup of your Shopware stack (inc. Shopware data, database and Caddy configuration), simply shut down the stack and archive the data directories mentioned in the [compose](./docker-compose.yml) file.

The commands listed below assume that you are inside the root of this repository on your system:

```sh
# Shut down all containers
docker compose down

# Create a tar archive in the parent directory
tar cvzf ../my-shopware-backup.tar.gz .

# Check the contents (remove the pipe to head to see all files)
tar tvf my-shopware-backup.tar.gz | head
```

You could also use `zip` or `7-Zip` to create a backup archive.

**It is recommended that you use `tar`, as it keeps track of permissions and ownerships.**

### Restoring from a backup
> If you just want to import a database from a SQL dump file, check the `Useful commands` section above.

To restore your Shopware stack from a backup, run the following steps:

1. Extract the backup archive.
    ```sh
    tar xvzf my-shopware-backup.tar.gz
    ```
2. `cd` into the new directory.
    ```sh
    cd my-shopware-backup
    ```
3. Ensure that the `site` directory is owned by `www-data`:
    ```sh
    ls -lh site
    ```

    If not, perform step 8 from the `Getting started` section.
4. Start the stack.
    ```sh
    docker compose up -d
    ```