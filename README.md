# scholarspace-hyrax [![Build Status](https://travis-ci.org/gwu-libraries/scholarspace-hyrax.png?branch=master)](https://travis-ci.org/gwu-libraries/scholarspace-hyrax)

A Hyrax app for GW Libraries with:
- two item types: GwWork and GwEtd
- roles: admin, content-admin

The public application is accessible at [https://scholarspace.library.gwu.edu/](https://scholarspace.library.gwu.edu)

Some convenient links to have handy:
- [Hyrax github repo](https://github.com/samvera/hyrax/)
- [Hyrax project](https://hyrax.samvera.org/)
- [Hyrax developer knowledge base](http://samvera.github.io/)

## Docker images

The Dockerized version of the ScholarSpace app uses the following images:

| Component | Image Name | Version | Source |
| --------- | ---------- | ------- | ------ | 
| Fedora server | ghcr.io/samvera/fcrepo4 | 4.7.5 | https://github.com/samvera-labs/docker-fcrepo | 
| Postgres (for Fedora) | postgres | 15.4 | https://hub.docker.com/_/postgres |
| Postgres (for Hyrax) | postgres | 9.5.25-alpine | https://hub.docker.com/_/postgres |
| Solr | library/solr | 6.4.2-alpine | Dockerfile-solr |
| Rails app | scholarspace-app | -- | Dockerfile | 
| Redis server | redis | 5-alpine | https://hub.docker.com/_/redis |
| Sidekiq | scholarspace-app | -- | Dockerfile |

## Notes on Docker images

### Fedora server
- The current version in production is 4.7.3. 
- The Docker image uses Jetty, not Tomcat. Configuring authentication for Jetty requires a different process, documented [here](https://wiki.lyrasis.org/display/FEDORA474/How+to+Configure+Servlet+Container+Authentication) and with examples in the `docker-fcrepo` repository. 

### Postgres
- Currently, separate postgres containers (each with their own Docker volume) are used for the Fedora and Rails databases. This may be desirable for migration purposes, i.e., if the two databases in production are running on different versions of postrgres. 
- The Rails/Hyrax postrgres container is using a version pinned to the version in use in production.


### Solr
- The Solr container is configured to run a script on startup that checks for the existence of a named Solr core (provided as an environment variable). 
- This image uses a base image that is one point release ahead of the version of Solr previously deployed in production (6.4.2 vs. 6.4.1). This is done to leverage a feature of the 6.4.2 image that facilitates implementation of the custom Hyrax schema. 
- If the core does not exist, it will be created, and the ScholarSpace schema will be applied.

### Rails/Hyrax app
- The image is built from the official Phusion/Passenger [image](https://github.com/phusion/passenger-docker/tree/rel-2.5.0).
- ScholarSpace dependencies are installed at build time.
- The version of Ruby is 2.7.3 (to match production).
- Instead of Apache, the image uses Nginx with Passenger.
- Files like `config/initializers/hyrax.rb` have been refactored to use environment variables where possible in order to minimize manual configuration. **When loading code from outside the container, such files will be overwritten by their external counterparts.**
- On startup, the container performs some runtime tasks (in `docker/scripts/scholarspace-setup.sh`): creating the scholarspace user and group, setting permissions, and creating a cron job for the sitemap generation.
- When the container starts, it launches the Passenger/Nginx process in the foreground. To acces the container (e.g., in order to use the Rails console), run `docker exec --user scholarspace [container-name] bash -l`. (Setting the `scholarspace` user and running `bash -l` are necessary to ensure that the RVM paths load correctly.)

### Sidekiq
- This container uses the same image as the Hyrax app, but instead of running Nginx, it runs the Sidekiq gem. 

## Setting up the application

1. Install the [Docker engine](https://docs.docker.com/engine/install/ubuntu/).
2. Edit `/etc/group` and add your user (e.g., `ubuntu`) to the `docker` group.
3. Run `id $USER` and note the values for `uid` and `gid`. Below you will add those to the `.env` file.  Note: You can create
a separate user for the app, but it is not necessary.  That user will need to own /opt/scholarspace and subdirectories.
4. Create an `opt/scholarspace` directory and clone the `scholarspace-hyrax` repository inside it. 
5. Create a directory for derivatives: `mkdir -p /opt/scholarspace/scholarspace-derivatives`.
    - For development, also create the following (empty) directories:
      ```
      /opt/scholarspace/certs 
      /opt/scholarspace/scholarspace-tmp 
      /opt/scholarspace/scholarspace-minter 
      ```
6. In `/opt/scholarspace/scholarspace-hyrax` run `cp example.env .env` to create the local environment file.
7. Edit `.env` to add the following values:
    - SCHOLARSPACE_GID, SCHOLARSPACE_UID 
    - HYRAX_DB_USER, HYRAX_DB_PASSWORD (for the Hyrax app database)
    - CONTACT_EMAIL
    - Variables under the `#Recaptch config` comment
    - RAILS_ENV and PASSENGER_APP_ENV (if other than production)
    - SMTP_USER and SMTP_PASSWORD
    - SERVER_NAME (hostname for Nginx)
    - NGINX_CERT_DIR and NGINX_KEY_DIR
    - SSL_ON (set to `true` if using)
    - `SSL_` variables (if using)
    - PERM_URL_BASE (used for persistent links) **Make sure to terminate the URL with a forward slash**.
    - FEDORA_PG_USER, FEDORA_PG_PASSWORD, FEDORA_USER, FEDORA_PASSWORD (username and password for the Fedora db backend and the Fedora app, respectively)
8. Configure ReCAPTCHA. 
    - Log in to the Google domain using the Google account that should have access to managing ReCAPTCHA API keys.  
    - Create ReCAPTCHA API keys at the [ReCAPTCHA admin console](https://www.google.com/recaptcha/admin).  
    - Register a new site (at https://www.google.com/recaptcha/admin/create).  Select the ReCAPTCHA v2 "I'm not a robot" Checkbox type.
    - In the `.env` file, set the ReCAPTCHA API keys:
        ```
          RECAPTCHA_SITE_KEY=
          RECAPTCHA_SECRET_KEY=
        ```
9. Adjust any other variables in the `.env` as needed.
10. Edit `docker-compose.yml` as necessary.
    - If running in development, change the volume mappings for the `sidekiq` and the `app-server` services and change the value for `POSTGRES_DB` under the `pg-hyrax` service definition.
    - If not using SSL, comment out the lines for the key and cert directories under the `app-server` service definition.
11. If migrating data, prepare the Solr core and Fedora database locally (see below). Otherwise, create the `/data/fedora` and `/var/solr/data` directories to store the Fedora files on the host (e.g, `sudo mkdir -p /data/fedora`).
12. Start the application containers by running `docker compose up -d`. This will build the Hyrax app/Sidekiq and Solr images locally and start all containers. Note that the app is not yet ready to view and there may be some errors in the log at this point.
13. If migrating data, restore the postgres database dumps for Fedora and Hyrax (see below).
14. The Hyrax server will not work without the value of `SECRET_KEY_BASE` being set in the `.env` file. To generate a secret key using Rails, run `docker exec -it --user scholarspace [app-server-container-name] bash -lc "docker/scripts/app-init.sh --create-secret"`. The `app-server-container-name` is probably `scholarspace-hyrax-app-server-1` but can be ascertained by running `docker ps`.
15. Add the secret key string to the `.env` file and restart the containers: `docker compose down && docker compose up -d`.
16.  If migrating data, run the Rake job to perform database migrations: `docker exec -it --user scholarspace [app-server-container-name] bash -lc "docker/scripts/app-init.sh --run-migrations"`. 
  - If creating a new instance (no migrated data), run the following command: 
      ```
      docker exec -it --user scholarspace [app-server-container-name] bash -lc "rails db:{drop,create,migrate}" 

  - In addition, when setting up a development instance, run `docker exec -it --user scholarspace [app-server-container-name] bash -lc "rails db:seed"`
    This command will populate the database with a few test works.
17. Visit the site in a web browser to trigger the Passenger app. (You won't see the compiled assets yet.)
18. Compile assets: `docker exec -it --user scholarspace [app-server-container-name] bash -lc "docker/scripts/app-init.sh --precompile-assets"`.
19. (Production only): Restart the Nginx server: `docker exec [app-container-name] bash -lc "passenger-config restart-app /"`. (In development mode, the `app-init.sh` script restarts the server by default after running any of the above options.)
20. The following additional steps may be useful in setting up a new instance (no migrated data), all of which can be run as options of the `app-init.sh` script:
    - `--create-roles`: create default app roles (if they don't already exist)
    - `--create-admin-set`: create the default Admin Set, if it doesn't already exist
    - `--add-admin-user`: grant a ScholarSpace user the `admin` role. To use: first, create the user in the ScholarSpace UI. Then run this command, inserting an environment variable (`admin_user=USER_EMAIL_ADDRESS`) before the path to the script. This environment variable will be used by the Rake task to look up the user in the app database. 
21. To generate a sitemap, run `docker exec -it --user scholarspace [sidekiq-container-name] bash -lc "docker/scripts/app-init.sh --create-sitemap"`. **This command should be run in the Sidekiq container, not the app server container.


## Data migration

### Solr

- To use an existing core (migration), do the following (before starting the container):
  - Place a copy of the parent core directory (i.e., scholarspace) in `/var/solr/data` on the Docker host. 
  - Grant ownership to the container's Solr user:  `chown -R 8983:8983 /var/solr/data`

### Fedora

- Place the various Fedora directories in the directory used in the bind-mount volume directive in the `docker-compose.yml` file, e.g., `/data/fedora`. 

### Postgres (Hyrax & Fedora)

- To migrate the Hyrax and Fedora postgres databases, the best approach is a backup/restore from production.
  - In this configuration, there is one container for each database. The services are named `pg-fcrepo` (Fedora) and `pg-hyrax`. Repeat these steps for each container. Each container uses a separate Docker volume: `db` and `db-hyrax`, respectively.
  - Make sure the container is running.
  - Copy the backup file to the associated container: `docker cp [db-backup-file.sql] [db-container-name]:/tmp`. This puts it in the /tmp directory inside the container.
  - Open an interactive session in the container: `docker exec -it [db-container-name] /bin/bash`.
  - To ensure proper migration, recreate the database before restoring using `template0`. (Restoring with the default template may cause errors.)
    - For the Fedora database, this might look like the following:
      `dropdb -U fedoraproduser fcrepo && createdb -U fedoraproduser -T template0 fcrepo`
    - For the Hyrax database:
      `dropdb -U scholarspace gwss_prod && createdb -U scholarspace -T template0 gwss_prod`
  - Perform the restore, using appropriate database, user, and file: `psql -U [scholarspace|fedoraproduser] -d [gwss_prod|fcrepo]` < [db-backup-file.sql]
  - Exit the container. 


## Setting up a new production instance

### (Optional) Install etd-loader

* Install the **etd-loader** application in `/opt/etd-loader` as per instructions at https://github.com/gwu-libraries/etd-loader

* When configuring `config.py`, ensure that it contains the following values:
  ```
  ingest_path = "/opt/scholarspace/scholarspace-hyrax"
  ingest_command = "rake RAILS_ENV=production gwss:ingest_etd"
  ```

### Create the user roles and the default Admin set

  1. Create an account in the UI for the admin user. (The email address of this account is referenced in step 2 below.)
  2. Run the rake tasks to user roles called `admin` and `content-admin` as well as the default Admin set:
  ```
          admin_user=YOUR_EMAIL_ADDRESS docker exec -it --user scholarspace [hyrax-app-container] bash -lc "docker/scripts/app-init.sh --create-roles --add-admin-user --create-admin-set"
  ```
  3. Add the `content-admin` users as desired through the `/roles` UI.

### Create `ETDs` admin set

Log in to the application as the admin user.  Navigate to the Administrative page, and create an Administrative set called `ETDs`.

### Customize UI

  1. Configure colors.  As the admin user, go to the admin dashboard --> Settings --> Appearance.  Set the Header background color to `004165` (You will need to select the color sliders, then RGB sliders, then enter the hex code in the Hex Color # box.)
 
  2. Also under Settings, add back Pages and Content Blocks 

 ## Persistence

- As currently configured, `docker-compose.yml` uses Docker volumes to persist storage for the Postgres databases.
- The Solr and Fedora containers are mapped to local directories on the host (*bind mounts*, in Docker jargon). 

## Deployment tips (production)

- When applying code changes with a persistent Docker volume (as used in production), it's necessary to delete both the image and the Docker volume that contains the old code. To facilitate this series of steps, you can run `script/redeploy-app.sh` from the `/opt/scholarspace/scholarspace-hyrax` directory (after making that script executable). This script will bring down all containers, delete the `scholarspace-app` image, delete the `app-hyrax` volume, and then restart all containers, rebuilding the image in the process. This script will also precompile the assets for the app as a last step.
- To avoid typing a long string whenever you want to access the Hyrax app container, you can assign an alias, in the `~/.bashrc` file, using the `docker ps` command to identify the app container, like so:
`alias hyrax-container='docker exec -it --user scholarspace $(docker ps --filter "name=app" -q) bash -l'`
- Likewise, an alias to restart Passenger in the app container (in production): 
`alias restart-hyrax='docker exec $(docker ps --filter 'name=app' -q) bash -lc "passenger-config restart-app /"'` 

## Development tips

- To facilitate recreating the entire app & environment from scratch (fresh install), you could use a script like the following:
```
#!/bin/bash

echo "Recreating Fedora and Solr directories"
rm -r /data/fedora && mkdir /data/fedora 
rm -r /var/solr/data && mkdir /var/solr/data && chown -R 8983:8983 /var/solr/data
echo "Cleaning up ScholarSpace files"
rm -r /opt/scholarspace/scholarspace-derivatives/derivatives
echo "Removing Docker volumes"
docker volume rm $(docker volume ls -q)

```
After bringing down the containers, run this script (with `sudo`) to clear out all persistent storage, including the Rails database, before bringing back up the containers. 

## Local Development Installation

For development of the Rails application, ScholarSpace can be run locally on macOS. This does not create a 1-to-1 replication of the production environment and does not use utilize Docker, but is intended as a minimal 

### Requirements
- Installation of [FITS 1.5.0](https://projects.iq.harvard.edu/fits/home)
  - Manual install: 
    - [Download Page](https://projects.iq.harvard.edu/fits/downloads)
  - Once installed, modify the `config.fits_path` in `config/initializers/hyrax.rb` to point to the installation path for FITS, i.e.
    ```ruby
    # Path to the file characterization tool
    config.fits_path = "/usr/local/bin/fits-1.5.0/fits.sh"
    ```

- Installation of [LibreOffice](https://www.libreoffice.org/)
  - If using Homebrew:
    - `brew install --cask libreoffice`
  - Manual install:
    - [Download Page](https://www.libreoffice.org/download/download-libreoffice/)
  - Once installed, modify the  `config.libreoffice_path` in `config/initializers/hyrax.rb` to point to the installation path for LibreOffice, i.e.
      - If installed via Homebrew, this path can be found by running `which soffice` in your terminal. 
    ```ruby
    # Path to the file derivatives creation tool
    config.libreoffice_path = "/usr/local/bin/soffice"
    ```

### Configuration
- In `config/environments/development.rb`, change the `config.active_job_queue_adapter` to `:inline` rather than `:sidekiq`
- Minimal .env configuration:
    ```ruby
    RAILS_ENV=development
    DEV_ADMIN_USER_EMAIL='admin@example.com'
    DEV_ADMIN_USER_PASSWORD='password'
    CURATION_CONCERNS=gw_work,gw_etd,gw_journal_issue
    PERM_URL_BASE = "a-permanent-url/"
    ACCESSIBILITY_URL="https://library.gwu.edu/found-problem?type_of_problem=a11y&a11y_problem_type=item&url=%{gwss_item_url}"
    ```
- You can set additional ENV options, but these are the only environment variables currently necessary for running in local development mode - all others can be commented out or deleted. 

### Preparing the Databases

- In a terminal, run `rails db:{drop,create,migrate}` in order to drop the development database (if it exists), create a new development database, and run the database migrations. 

### Launching the Server

- In a terminal, run `rails hydra:server`
- If this is the first time you have run this command, it will install an instance of Solr and an instance of Fedora4 in `tmp`, and create directories in `tmp` for derivatives and uploads.
- Once Solr and Fedora are installed, this will launch the Rails application (port `3000` by default), Solr (port `8983` by default), and Fedora (port `8984` by default).
- At this point, you should be able to load the application by visiting `localhost:3000` in your browser.

### Seeding the Database

- *With the Rails, Solr, and Fedora processes running*, run `rails db:seed`
  - This can be accomplished by opening another terminal window in the same directory. 
- Seeding the database creates:
  - Default admin and content-admin roles
  - An admin user, with credentials specified with `DEV_ADMIN_USER_EMAIL` and `DEV_ADMIN_USER_PASSWORD`, and a content-admin user with username `content-admin@example.com` and password `password`.
  - Default admin set, admin set collection type, and user collection type.
  - ETDs admin set
  - A journal collection (`GW Undergraduate Review`)
  - Uploads and processes files contained in `spec/fixtures` to create demo works. You can add or remove files from the `authenticated_etds`, `journal_collection`, `private_etds`, and `public_etds` folders to change the demonstration files. 