# Shopware 6 Docker Stack

The stack consists of:
 - PHP 8.3 (FPM) under Debian Bullseye
 - MySQL 8.0.40 under Debian
 - Caddy (latest stable)

The [compose](./docker-compose.yml) stack will take care of building a customized PHP container image with the necessary extensions.

- [x] Pre-configured Caddy server (except domain)
  - [x] Automatic HTTP->HTTPS redirect
  - [x] Root to `www.` redirection
  - [x] Dotfiles blocked (except `.well-known/`)
- [x] Pre-configured MySQL 8.0.40
  - [x] Secure access - inaccessible from outside, even the host itself
- [x] Pre-configured PHP 8.3.15 for Shopware
  - [x] Pre-installed modules: `mbstring`, `gd`, `intl`, `pdo_mysql`, `zip`
  - [x] Pre-configured and enabled opcache
  - [x] Increased memory limit to 1G
  - [x] Increased execution time limit to *3m*
- [x] Pre-configured Cron jobs for Shopware 6
  - `messenger:consume`
    - Runs at *01:00 AM*
    - Time limit: *2min*
    - Memory limit: *512MB*
  - `scheduled-task:run`
    - Runs at *00:00 AM*
    - Time limit: *2min*
    - Memory limit: *512MB*

## Getting started
Before you start, you may change the default database password in [the compose file](./docker-compose.yml). Do not attempt to create additional database users, you cannot grant permissions due to how restricted the database is. If you really want this, you'll need to at least temporarily open the MySQL port on the container.

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
    cd site
    wget https://github.com/shopware/web-recovery/releases/latest/download/shopware-installer.phar.php
    cd ..
    ```
8. Change ownership of the `site` directory to the `www-data` user and group:
    ```sh
    chown -hR www-data:www-data site
    ```
9. Run the stack using Docker Compose.
    ```sh
    docker compose up
    ```
    *You can add `-d` to run it in the background.*
10. Complete the initial Shopware setup.
11. Shut down the server with Ctrl-C or `docker compose down` if it's running in the background.
12. Edit the `Caddyfile` so that the **root folder** is `/app/public/public`.
13. Restart the server according to step 9.
14. Complete the Shopware database configuration. Wait until the page is no longer loading after clicking `Next` during the `Configuration` step.
15. Open the admin panel by going to `/admin` (E.g. `https://example.com/admin`).
16. Complete the first-time setup.

## Post-setup
Before performing these steps:
1. Make sure you're in the root directory of this repo.
2. Shut down the stack.

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

## Useful commands
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
  docker exec -it mysql bash
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
  <summary>Use MySQL CLI</summary>
  
  ```sh
  docker exec -it mysql mysql -u root --password=shopware -D shopware
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