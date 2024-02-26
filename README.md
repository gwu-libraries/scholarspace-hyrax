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
- Currently, separate postgres containers (each with their own Docker volume) are used for the Fedora and Rails databases. This may be desirable for migration purposes, i.e., if the two databases in production are running on different versions of postgres. 
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
    - SMTP_USER and SMTP_PASSWORD
    - SERVER_NAME (hostname for Nginx)
    - NGINX_CERT_DIR and NGINX_KEY_DIR
    - SSL_ON (set to `true` if using)
    - `SSL_` variables (if using)
    - PERM_URL_BASE (used for persistent links) **Make sure to terminate the URL with a forward slash**.
    - FEDORA_PG_USER, FEDORA_PG_PASSWORD, FEDORA_USER, FEDORA_PASSWORD (username and password for the Fedora db backend and the Fedora app, respectively)
    - SOLR_DATA_DIR (directory for Solr cores on host machine)
    - FEDORA_DATA_DIR (directory for Fedora data on host machine)
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
    - If not using SSL, comment out the lines for the key and cert directories under the `app-server` service definition.
11. If migrating data, prepare the Solr core and Fedora database locally (see below). Otherwise, create the `/opt/scholarspace/fedora-data` and `/opt/scholarspace/solr-data` directories to store the Fedora files on the host (e.g, `sudo mkdir -p /opt/scholarspace/fedora-data`).
12. Start the application containers by running `docker compose up -d`. This will build the Hyrax app/Sidekiq and Solr images locally and start all containers. Note that the app is not yet ready to view and there may be some errors in the log at this point. If you get an authentication error, see the section on [authenticating to the GitHub Container Registry](#authenticating-to-ghcr) below. 
13. If migrating data, restore the postgres database dumps for Fedora and Hyrax (see below).
14. The Hyrax server will not work without the value of `SECRET_KEY_BASE` being set in the `.env` file. To generate a secret key using Rails, run `docker exec -it --user scholarspace [app-server-container-name] bash -lc "docker/scripts/app-init.sh --create-secret"`. The `app-server-container-name` is probably `scholarspace-hyrax-app-server-1` but can be ascertained by running `docker ps`.
15. Add the secret key string to the `.env` file and restart the containers: `docker compose down && docker compose up -d`.
16.  If migrating data, run the Rake job to perform database migrations: `docker exec -it --user scholarspace [app-server-container-name] bash -lc "docker/scripts/app-init.sh --run-migrations"`. 
  - If creating a new instance (no migrated data), run the following command: 
      ```
      docker exec -it --user scholarspace [app-server-container-name] bash -lc "rails db:{drop,create,migrate,seed}" 
      ```
17. Visit the site in a web browser to trigger the Passenger app. (You won't see the compiled assets yet.)
18. Add initial content blocks and precompile assets: `docker exec -it --user scholarspace [app-server-container-name] bash -lc "docker/scripts/app-init.sh --apply-content-blocks --precompile-assets"`.
19. (Production only): Restart the Nginx server: `docker exec [app-container-name] bash -lc "passenger-config restart-app /"`. 
20. The following additional steps may be useful in setting up a new instance (no migrated data), all of which can be run as options of the `app-init.sh` script:
    - `--create-roles`: create default app roles (if they don't already exist)
    - `--create-admin-set`: create the default Admin Set, if it doesn't already exist
    - `--add-admin-user`: grant a ScholarSpace user the `admin` role. To use: first, create the user in the ScholarSpace UI. Then run this command, inserting an environment variable (`admin_user=USER_EMAIL_ADDRESS`) before the path to the script. This environment variable will be used by the Rake task to look up the user in the app database. 
21. To start the job to generate a sitemap, run `docker exec -it --user scholarspace [app-container-name] bash -lc "docker/scripts/app-init.sh --create-sitemap"`. With default configurations, this job will run every morning at 12:30 AM, or can be configured in `config/schedule.rb` to run on a different schedule.

## Redeployment

For convenience with prod deployments, use the redeploy script:
```
sudo chmod u+x script/redeploy-app.sh 
./script/redeploy-app.sh
```
This script will perform the following actions:
 - Gracefully stop and remove all containers
 - Delete the ScholarSpace and Solr custom images
 - Delete the Docker volume associated with the ScholarSpace image
 - Restart the containers
 - Precompile the app's assets

It will still be necessary to restart the app container after visiting the site (in order to the compiled assets to be visible).

## Authenticating to GHCR

The ScholarSpace app and Solr Docker images are hosted on GitHub's Container Registry. Since the images are not public (by GW policy), pulling images from the registry requires user authentication with a personal access token. 

1. Log into your GitHub account and visit [https://github.com/settings/tokens](https://github.com/settings/tokens) (under Developer Settings). 
2. Either select an existing access token or create a new one. 
3. Grant the token the `write:packages` or (minimally) `read:packages` permission.
4. Once you have copied your token to a secure location, select the option to Configure SSO on the token.
5. At the command line on the server where you're install ScholarSpace, do the following steps to log into the GHCR, using your GitHub username and the token you have created.
```
export CR_PAT=[YOUR_TOKEN]
echo $CR_PAT | docker login ghcr.io -u [USERNAME] --password-stdin
```
6. Now run `docker compose up -d`.

## Data migration

### Solr

- To use an existing core (migration), do the following (before starting the container):
  - Place a copy of the parent core directory (i.e., scholarspace) in `/opt/scholarspace/solr-data` on the Docker host. 
  - Grant ownership to the container's Solr user:  `chown -R 8983:8983 /opt/scholarspace/solr-data`

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

### Migrating Production Database

In the app-server container (i.e. through `docker exec -it scholarspace-hyrax_app-server_1 /bin/sh`, followed by `su scholarspace`), run:

`bundle exec rails db:migrate RAILS_ENV=production`

### Creating First Admin User and Necessary Admin Sets/Collections

In the app-server container (i.e. through `docker exec -it scholarspace-hyrax_app-server_1 /bin/sh`, followed by `su scholarspace`), run this rake task - replacing email and password with your new admin user email and password:

`bundle exec rails gwss:prep_new_prod RAILS_ENV=production admin_user="AN-EMAIL-ADDRESS@EXAMPLE.COM" admin_password="A-PASSWORD"`

This will create the admin and content-admin roles, create an admin user with the specified email and password, create the default admin sets, and create an `ETDs` admin set with the admin user as the owner.

In addition, this task will precompile assets for production.

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

# Development Mode

### Preparing Development Databases

NOTE: The following steps assume that Docker containers have launched successfully and are currently running. 

To prepare a development server:
- Run `docker exec -it scholarspace-hyrax_app-server_1 /bin/sh`
	- This will give you access to an interactive terminal (`-it`) in the container with the Rails application.
- Switch to the in-container "scholarspace" user with `su scholarspace`
- Run:
	- `bundle exec rails db:create` to create the `development` and `test` databases.
	- `bundle exec rails db:migrate` to run the database migrations for the `development` and `test` databases. 
	- `bundle exec rails db:seed` to create (in the `devleopment` environment): 
		- An admin role and user (email and password set in `.env`)
		- A content admin role and user (email and password set in `.env`)
		- The default admin set
		- The admin set collection type
		- The user collection type
		- An `ETDs` admin set

### Running a Development Application

From a terminal attached to the Rails application container (i.e. through `docker exec -it scholarspace-hyrax_app-server_1 /bin/sh`), run:

- `bundle exec rails s -b 0.0.0.0` 

This command starts a Passenger/NGINX server running Rails in `development` mode on port 3000, accessible at:
- http://YOUR-EC2-INSTANCE-URL.compute.amazonaws.com:3000 (assuming AWS security groups have been configured to allow traffic on port 3000)

As you interact with the `development` application in a browser, the logs will output to the terminal where you ran the `bundle exec rails s -b 0.0.0.0` command, with a `debug` level of detail. 

To stop the `development` server, press `ctrl + c` in the terminal where you ran the command to start the server.  You can restart the development application, and previous changes (i.e. deposited works, created collections, etc) should persist. 
