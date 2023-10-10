# scholarspace-hyrax [![Build Status](https://travis-ci.org/gwu-libraries/scholarspace-hyrax.png?branch=master)](https://travis-ci.org/gwu-libraries/scholarspace-hyrax)

A Hyrax app for GW Libraries with:
- two item types: GwWork and GwEtd
- roles: admin, content-admin

The public application is accessible at [https://scholarspace.library.gwu.edu/](https://scholarspace.library.gwu.edu)

Some convenient links to have handy:
- [Hyrax github repo](https://github.com/samvera/hyrax/)
- [Hyrax project](http://hyr.ax/)
- [Hyrax developer knowledge base](http://samvera.github.io/)

# Getting started

The recommended production setup involves two servers.  However, these can be the same server if needed, for example in a development environment.
- Repository server, for the Fedora repository and Solr interface
- Application server, for the GW ScholarSpace rails app

Currently these instructions are for an Ubuntu 20.04 repository server, and an Ubuntu 20.04 application server.

# Repository server

* Install Java 8

  - For Ubuntu 20:
    ```
      sudo apt-get install openjdk-8*
    ```
    Verify that Java has been installed and is running Java 8:
    ```
      java -version
    ```
   This should return Java version 1.8.
   
* Install necessary Ubuntu packages:
  ```
      sudo apt-get install git postgresql libpq-dev unzip clamav-daemon curl tomcat8 libcurl4-openssl-dev libapr1-dev libaprutil1-dev
  ```

* Create needed directories:
  ```
    sudo mkdir /opt/install
    sudo mkdir /opt/fedora; sudo chown tomcat8:tomcat8 /opt/fedora
    sudo mkdir /etc/fcrepo
  ```

## Tomcat 8 setup

* Configure Tomcat8 Java settings:

  Retrieve ```tomcat_conf/tomcat8``` file from this github repository and overwrite ```/etc/default/tomcat8```
  
  Make sure that the `JAVA_HOME` value corresponds to the correct Java installation directory.  If not, update `JAVA_HOME`.
  
## Solr setup

* Install Solr (may require `sudo`):

NOTE: While GW ScholarSpace has not been tested with Solr 7.7.1, a plain Hyrax 2.5.0 instance works with Solr 7.7.1, so it is likely to work with a new instance of GW ScholarSpace.  Current (as of GW ScholarSpace v1.2.0) prod and test instances are running Solr 6.4.1 and should be upgraded at a later date.
```
  cd /opt/install
  wget http://archive.apache.org/dist/lucene/solr/6.4.1/solr-6.4.1.tgz
  tar xzf solr-6.4.1.tgz solr-6.4.1/bin/install_solr_service.sh --strip-components=2
  sudo ./install_solr_service.sh solr-6.4.1.tgz
```
* Verify that Solr started
  ```
    sudo service solr status
  ```

* Configure a Solr core:
  ```
    sudo su - solr -c "/opt/solr/bin/solr create -c scholarspace -n /opt/install/solr/config"
  ```
* Convert the new Solr core from `managed-schema` to `schema.xml` support:
  ```
    sudo mv /var/solr/data/scholarspace/conf/managed-schema /var/solr/data/scholarspace/conf/managed-schema.bak
  ```
* Copy the `solr/conf/` contents from the [samvera/hyrax repo](https://github.com/samvera/hyrax/tree/v2.0.3/solr/config) to `/var/solr/data/scholarspace/conf/` (this can be accomplished by git clone-ing the hyrax repo, making sure to check out the appropriate tag)

* Apply the December 2021 security remediation:

  As per https://solr.apache.org/news.html (see Dec. 10, 2021 entry):

  Edit `/etc/default/solr.in.sh` to include: `SOLR_OPTS="$SOLR_OPTS -Dlog4j2.formatMsgNoLookups=true"`
  
* Restart Solr:
  ```
    sudo service solr restart
  ```

## Fedora setup

### Optional: Back up existing Fedora

*  If creating a new repository, skip this step.

  Create a backup of the existing Fedora instance
  ```
      sudo mkdir /opt/fedora_backups
      sudo chown -R tomcat8:tomcat8 /opt/fedora_backups
      curl -X POST -u <FedoraUsername>:<FedoraPassword> --data "/opt/fedora_backups" yourserver.com/fcrepo/rest/fcr:backup
  ```
  Verify that a backup was created in `/opt/fedora_backups` before proceeding

### Set up a PostgreSQL database for Fedora

* Create a postgreSQL database user and database for Fedora
  ```
    sudo su - postgres
    (postgres)% psql
    postgres=# create user YOURDBUSERNAME with createdb password 'YOURDBPASSWORD';
    postgres=# \q
    (postgres)% createdb -O YOURDBUSERNAME ispn
    (postgres)% exit
  ```
   Note the database name for Fedora must be `ispn`

   Edit `/etc/default/tomcat8` and update these settings with the ispn database username and password, replacing the
   placeholders for these values:

  ```
    JAVA_OPTS="${JAVA_OPTS} -Dfcrepo.postgresql.username=<ADD ISPN DB USERNAME HERE>"
    JAVA_OPTS="${JAVA_OPTS} -Dfcrepo.postgresql.password=<ADD ISPN DB PASSWORD HERE>"
  ```

### Create a Fedora settings folder
  ```
    sudo mkdir /etc/fcrepo
  ```
* Copy `tomcat_conf/fcrepo/infinispan.xml` from the Github repo to `/etc/fcrepo/infinispan.xml`.  Set the ownership to tomcat8:

  ```
    sudo chown -R tomcat8:tomcat8 /etc/fcrepo
  ``` 

### Set up Fedora webapp

* Copy fcrepo WAR file to tomcat8
  ```
    cd /opt/install
    wget https://github.com/fcrepo/fcrepo/releases/download/fcrepo-4.7.1/fcrepo-webapp-4.7.1.war
    sudo cp fcrepo-webapp-4.7.1.war /var/lib/tomcat8/webapps/fcrepo.war
  ```
* Wait for tomcat to deploy the war file before proceeding to the next step.  This can be verified by watching `/var/log/tomcat8/catalina.out`
   
* Copy the `tomcat_conf/fcrepo-webapp/web.xml` file from the Github repo to `/var/lib/tomcat8/webapps/fcrepo/WEB-INF/web.xml` 
   
* Ensure that tomcat8 library files are all still owned by tomcat8
  ```
    sudo chown -R tomcat8:tomcat8 /var/lib/tomcat8
  ```
* Set up Fedora authentication by copying the `tomcat_conf/tomcat-users.xml` file from the Github repo and overwrite `/etc/tomcat8/tomcat-users.xml`.   Edit `tomcat-users.xml` and replace the dummy passwords with your preferred secure passwords.  (Be sure that your passwords don't contain any characters considered special characters in XML, such as `<`,`>`,`&`,`'`,`"`)
   
* Edit `/var/lib/tomcat8/webapps/fcrepo/WEB-INF/classes/config/jdbc-postgresql/repository.json` to change the database name from `fcrepo` to `ispn`.

* Restart Tomcat
  ```
    sudo service tomcat8 restart
  ```
  Check `/var/log/tomcat8/catalina.out` to ensure that tomcat8 restarted and deployed fcrepo with no errors.


* OPTIONAL:  To restore from a Fedora backup:
  ```
    curl -X POST -u <FedoraUsername>:<FedoraPassword> --data "/opt/fedora_backups" yourserver.com/fcrepo/rest/fcr:restore
  ```
    Restart tomcat and validate that the repository has been restored:
  ```
    sudo service tomcat8 restart
  ```

# Application server

Start with an Ubuntu 18 server.

### Install dependencies

* Install necessary Ubuntu packages:
  ```
          sudo apt update
          sudo apt install git postgresql libpq-dev redis-server unzip clamav-daemon curl imagemagick libreoffice libcurl4-openssl-dev apache2 apache2-dev ffmpeg gnupg2 libxml2 libxml2-dev
  ```
* Install RVM for multi-users.  If the GPG signature verification fails at this step, just follow the instructions in the warning in order to fetch the public key.
  ```
          curl -L https://get.rvm.io | sudo bash -s stable
          source /etc/profile.d/rvm.sh
  ```
  Edit `/etc/group` and add yourself (and any other users who will need to run rvm) to the `rvm` system group.  You may then need to log back out and back in as that user.
   
  Log out, then log back in.
  
* Install Ruby:
  ```
          rvm install ruby-2.7.3
  ```
* Install Rails:
  ```
          gem install rails -v 5.2.7 -N
  ```
  Also, add `export rvmsudo_secure_path=1` to your user's `.bashrc` file.  This will avoid a warning when running `rvmsudo`.

* Create directories
  ```
          mkdir /opt/scholarspace
          mkdir /opt/install
          mkdir /opt/xsendfile
  ```
* Create the necessary users and user groups, and assign folder permissions
  ```
          sudo adduser --disabled-password scholarspace
  ``` 
   This also creates a `scholarspace` group.  Edit `/etc/group` and add users (including `www-data`) to the new `scholarspace` group.  Additionally, add the `scholarspace` user to the `rvm` group.
  ```    
          sudo chown scholarspace:scholarspace /opt/scholarspace
          sudo chown www-data:www-data /opt/xsendfile
  ```
* Get the GW ScholarSpace code:
  ```
          sudo su - scholarspace
          cd /opt/scholarspace
          git clone https://github.com/gwu-libraries/scholarspace-hyrax.git
  ```
  Check out the desired tag, where `TAGNUMBER` might be, for example, `1.2.0`:
  ```
          cd scholarspace-hyrax
          git checkout TAGNUMBER
  ```

* Install gems
  ```
          gem install bundler
          bundle install --without development --deployment
  ```
  More information on the meaning of these bundle install options can be found at https://bundler.io/v2.0/man/bundle-install.1.html .  For a development environment, to install development gems as well, omit the `--without development` option.
  
  Return to your user account:
  ```
          exit
  ```

* Create a postgresql user for scholarspace
  ```
          sudo su - postgres
          (postgres)% psql
          postgres=# create user YOURDBUSERNAME with createdb password 'YOURSFMDBPASSWORD';
  ```
  The result should be:
  ```
          CREATE ROLE
  ```
* Create three databases (e.g. scholarspace_dev, scholarspace_test, scholarspace_prod)
   ```
        postgres=# \q
        (postgres)% createdb -O YOURDBUSERNAME YOURDEVDBNAME
        (postgres)% createdb -O YOURDBUSERNAME YOURTESTDBNAME
        (postgres)% createdb -O YOURDBUSERNAME YOURPRODDBNAME
        (postgres)% exit
   ```
* Create the `hyrax.rb` file
   ```
        sudo su - scholarspace
	cd config/initializers
        cp hyrax.rb.template hyrax.rb
   ```
  Customize `hyrax.rb` as needed.

* Create the `database.yml` file
  ```
          sudo su - scholarspace
          cd config
          cp database.yml.template database.yml
  ```
  Edit `database.yml` to add your specific database names and credentials

* Create the `solr.yml` file
  ```
          cp solr.yml.template solr.yml
  ```
  Edit `solr.yml` to add the URL of the Solr instance(s).

* Create the `blacklight.yml` file
  ```
          cp blacklight.yml.template blacklight.yml
  ```
  Edit `blacklight.yml` to add the URL of the Solr instance(s).

* Create the `fedora.yml` file
  ```
          cp fedora.yml.template fedora.yml
  ```
  Edit `fedora.yml` to add the URL of the Fedora repository(/-ies).  Make sure to add the password you configured in `tomcat-users.xml` when setting up Fedora.

* Create the secure secret key. In production, put this in your environment, not in the file.
  ```
          cd ..
          bundle exec rake secret
  ```
  Copy the key to your clipboard.
  ```
          cd config
          cp secrets.yml.template secrets.yml
  ```
  (For a dev or test environment, paste secret keys into the `secrets.yml` file.)
  For a production environment, as root, add the following to the bottom of `/etc/profile`, substituting the actual key value that you copied above:
  ```
          export SECRET_KEY_BASE=<the secret key you generated above>
  ```
  Additionally, add it to the `sidekiq_conf/sidekiq.service` file, to the line that sets the environment variable:
  ```
  Environment=SECRET_KEY_BASE=
  ```

* Run the database migrations.
  ```
          rake db:migrate RAILS_ENV=production
  ```
  If you get an error about rake versions, this can be resolved with:
  ```
          gem install rake -v 13.0.3   # or other desired version
  ```

* Copy the production environment configuration:
  ```
          cp config/environments/production.rb.template production.rb
  ```

* Install `fits.sh` version 1.5.0 (check [FITS](http://projects.iq.harvard.edu/fits/downloads) for the latest 1.5.0 download).  Also check the [Hyrax repo](https://github.com/samvera/hyrax/blob/main/documentation/developing-your-hyrax-based-app.md#prerequisites) to verify the latest recommended version of FITS for use with Hyrax.
  ```
          cd /usr/local/bin
          sudo wget https://github.com/harvard-lts/fits/releases/download/1.5.0/fits-1.5.0.zip
          sudo unzip fits-1.5.0.zip -d fits-1.5.0
          sudo rm fits-1.5.0.zip
          cd fits-1.5.0
          sudo chmod a+x fits*.sh
  ```

### Configure the `minter-state` file path

TODO: Currently minter-state is actually using the database, not a file.

* Create a minter folder
  ```
          sudo mkdir /opt/scholarspace/scholarspace-minter
          sudo chown -R scholarspace:scholarspace /opt/scholarspace/scholarspace-minter
  ```
  If an existing `minter-state` file exists in `/tmp/minter-state` copy it to the new folder
  ```     
          cp /tmp/minter-state /opt/scholarspace/scholarspace-minter/
  ```
  Verify that `config.minter_statefile` in `config/initializers/hyrax.rb` matches the path of the new minter directory:
  ```
          config.minter_statefile = '/opt/scholarspace/scholarspace-minter/minter-state'
  ```

### Configure the tmp path
  
  * Create a tmp folder  
  ```
          sudo mkdir /opt/scholarspace/scholarspace-tmp
          sudo chown -R scholarspace:scholarspace /opt/scholarspace/scholarspace-tmp
  ```
  * Verify that `config.temp_file_base` in `config/initializers/hyrax.rb` matches the path of the new tmp directory:
  ```
          config.temp_file_base = '/opt/scholarspace/scholarspace-tmp'
  ```

### Configure path for libre-office

  * Verify that `config.libreoffice_path` in `config/initializers/hyrax.rb` is as follows:
  ```
          config.libreoffice_path = "/usr/bin/soffice"
  ```
### Configure derivatives path for Hyrax

  * Create a derivatives folder on your application server, writeable to any user in the scholarspace group:
  ```
          sudo mkdir /opt/scholarspace/scholarspace-derivatives
          sudo chown -R scholarspace:scholarspace /opt/scholarspace/scholarspace-derivatives
          sudo chmod 775 -R /opt/scholarspace/scholarspace-derivatives
  ```
  * Add `config.derivatives_path` to `config/initializers/hyrax.rb`
  ```
          config.derivatives_path = "/opt/scholarspace/scholarspace-derivatives/"
  ```

### Configure Contact form emailing

  * In `config/initializers/hyrax.rb`, set the email to which contact form submissions will be sent:
  ```
          config.contact_email = 
  ```

  * Configure the account from which contact form emails will be sent, in `config/environments/production.rb` (or other desired environment), by configuring the user name and password in the `config.action_mailer.smtp_settings` block.
  
  * (Optional) Edit `config/initializers/mailboxer.rb` with email account from which to send messages and notifications:
  ```
          config.default_from = 
  ```

### Configure geonames username

  * In `config/initializers/hyrax.rb`, set the geonames username:
  ```
          config.geonames_username =
  ```

### Configure ReCAPTCHA

* Log in to the Google domain using the Google account that should have access to managing ReCAPTCHA API keys.  Create ReCAPTCHA API keys at the [ReCAPTCHA admin console](https://www.google.com/recaptcha/admin).  Register a new site (at https://www.google.com/recaptcha/admin/create).  Select the ReCAPTCHA v2 "I'm not a robot" Checkbox type.
* In `/opt/scholarspace/scholarspace-hyrax/.env`, set the ReCAPTCHA API keys:
```
   RECAPTCHA_SITE_KEY=
   RECAPTCHA_SECRET_KEY=
```

### Configure Passenger and Apache2

* Set up Passenger, and create Passenger config for Apache
  ```
          gem install passenger -v 6.0.14
          rvmsudo passenger-install-apache2-module
  ```
   Select Ruby from the list of languages.  The install script will direct you to copy several lines for the Apache configuration.  They will look something similar to:
  ```  
  LoadModule passenger_module /usr/local/rvm/gems/ruby-2.7.3/gems/passenger-6.0.14/buildout/apache2/mod_passenger.so
  <IfModule mod_passenger.c>
    PassengerRoot /usr/local/rvm/gems/ruby-2.7.3/gems/passenger-6.0.14
    PassengerDefaultRuby /usr/local/rvm/gems/ruby-2.7.3/wrappers/ruby
  </IfModule>
  ```
  Create `/etc/apache2/conf-available/passenger.conf` using the lines pasted from the Passenger install script.

  Add the following line into `passenger.conf` (below the `<IfModule></IfModule>` node):

        PassengerAllowEncodedSlashes on

    
* Enable the Apache `passenger.conf` file and the rewrite Apache mod
  ```
          sudo a2enconf passenger
          sudo a2enmod rewrite
          sudo service apache2 restart
  ```
* Create and enable an Apache2 virtual host

  Retrieve `scholarspace.conf` from `apache_conf/scholarspace.conf` in the GitHub repo; copy to `/etc/apache2/sites-available/scholarspace.conf`
     
  Retrieve `scholarspace-ssl.conf` from `apache_conf/scholarspace-ssl.conf` in the GitHub repo; copy to `/etc/apache2/sites-available/scholarspace-ssl.conf`.  Adjust paths as needed.
     
  Enable modssl:
  ```
          sudo a2enmod ssl
  ```

* Generate certificates and place them in paths referenced in `scholarspace-ssl.conf` (modify the paths in `scholarspace-ssl.conf` if needed).  Cert file names should also match. For a development instance, a self-signed cert is an option. Instructions provided here: https://github.com/gwu-libraries/ssl_howto
  ```
          sudo a2dissite 000-default.conf
          sudo a2ensite scholarspace.conf
          sudo a2ensite scholarspace-ssl.conf
  ```
  If you are not implementing Shibboleth, you MUST remove the lines in `scholarspace-ssl.conf` referencing shibboleth.

* Install `mod_xsendfile`
  ```
          cd /opt/install
          git clone https://github.com/nmaier/mod_xsendfile.git
          cd mod_xsendfile
          sudo apxs2 -cia mod_xsendfile.c
          sudo service apache2 restart
  ```

### (Optional) Install etd-loader

* Install the **etd-loader** application in `/opt/etd-loader` as per instructions at https://github.com/gwu-libraries/etd-loader

* When configuring `config.py`, ensure that it contains the following values:
  ```
  ingest_path = "/opt/scholarspace/scholarspace-hyrax"
  ingest_command = "rake RAILS_ENV=production gwss:ingest_etd"
  ```

### Set policy for file uploads

Edit `/etc/ImageMagick-6/policy.xml` to allow/disallow file types that may be processed
for derivatives.  For example, to allow PDF files, remove the line that blocks PDF files.

### Set up Sidekiq as a daemon process

*  Copy `sidekiq_conf/sidekiq.service` to `/lib/systemd/system` and set ownership to root.  Verify that the application path, rvm path, and queue names in `sidekiq.service` are consistent with the current deployment locations and queue names.
*  You may need to start Sidekiq using `sudo service sidekiq start` after this initial setup.  This should not be necessary after system reboots.
*  Make sure that `production.rb` is set to use sidekiq as the `queue_adapter` as per `production.rb.template`


### Final Deployment

* Prepare databases and assets for production
  ```
          cd /opt/scholarspace/scholarspace-hyrax
          rake assets:precompile RAILS_ENV=production 
          sudo service apache2 restart
  ```    
 
### Create the user roles

  Run the rake task that creates user roles called `admin` and `content-admin`:
  ```
          rake gwss:create_roles RAILS_ENV=production
  ```
  At the rails console, add an initial user to the `admin` role.  Make sure that your admin user has logged in at least once via the app's web UI (which should now be working).
  ```
          % RAILS_ENV=production rails c
          > r = Role.find_by_name('admin')
          > r.users << User.find_by_user_key('YOUR_ADMIN_USER_EMAIL@gwu.edu')
          > r.save 
  ```
  We can [add the content-admin users](#prod-add-content-admin) as desired through the /roles UI.


### Create `ETDs` admin set

* First, create the default administrative set (Hyrax won't allow you to create any admin sets until you've created this first one):

  ```
          su - scholarspace
          cd /opt/scholarspace/scholarspace-hyrax
          RAILS_ENV=production rake hyrax:default_admin_set:create
  ```

* Log in to the application as the admin user.  Navigate to the Administrative page, and create an Administrative set called `ETDs`.

### Populate the initial content blocks

* Log in as the admin user.  Edit the Above and Help pages; paste in the HTML from the repo **TODO: Add initial HTML to repo**

### (Optional) Enable citation pages

 * Uncomment the following line in `config/initializers/hyrax.rb` and set to `true`
 
         config.citations = true

### Post-deployment

  * [Add content-admin users](https://github.com/gwu-libraries/scholarspace-hyrax/wiki/Adding-content-admin-users)
  
  * Generate sitemap
  ```
  bundle exec rake gwss:sitemap_queue_generate RAILS_ENV=production
  ```

  * Set up cron job for sitemap generation

  Run `whenever` to read `config/schedule.rb` and generate the recommended command with which to configure the cron job.
  ```
  bundle exec whenever
  ```
  Use the output provided by `whenever` to create a cron job.  A recommended approach is to (as the `scholarspace` user) run `crontab -e` to edit the cron jobs.  Your crontab might include a job that looks like this:
  ```
# m h  dom mon dow   command
0 0 * * * /bin/bash -l -c 'cd /opt/scholarspace/scholarspace-hyrax && RAILS_ENV=production bundle exec rake gwss:sitemap_queue_generate --silent >> /opt/scholarspace/scholarspace-hyrax/log/wheneveroutput.log 2>&1'
  ```
 
  * Set up log rotation.  `production.log` can grow quite large, quite quickly, without any sort of compression and/or rotation configured.  A typical `logrotate` configuration would entail adding a configuration file into `/etc/logrotate.d/`.  For example, create a file in `/etc/logrotate.d/` called `scholarspace-hyrax` containing the following:
  ```
  /opt/scholarspace/scholarspace-hyrax/log/production.log {
          daily
          missingok
          rotate 10
          compress
    delaycompress
          notifempty
          create 664 scholarspace scholarspace
  }
  ```

 * Configure colors.  As the admin user, go to the admin dashboard --> Settings --> Appearance.  Set the Header background color to `004165` (You will need to select the color sliders, then RGB sliders, then enter the hex code in the Hex Color # box.)
 
 * Also under Settings, add back Pages and Content Blocks 
   
### (NEEDS REFRESH - see [#83](https://github.com/gwu-libraries/scholarspace-hyrax/issues/83)) (Optional) Add Google Analytics

* Enable Google Analytics in `config/initializers/hyrax.rb` by editing the following lines:

         # Enable displaying usage statistics in the UI
         # Defaults to FALSE
         # Requires a Google Analytics id and OAuth2 keyfile.  See README for more info
         config.analytics = true
        
         # Specify a Google Analytics tracking ID to gather usage statistics
         config.google_analytics_id = 'UA-99999999-1'

         # Specify a date you wish to start collecting Google Analytic statistics for.
         config.analytic_start_date = DateTime.new(2015,11,10)

* Copy the `analytics.yml.template` file in config

        cp config/analytics.yml.template config/analytics.yml

* Populate the `analyitcs.yml` file with your Google Analyitcs credentials.  See: https://github.com/samvera/hyrax/wiki/Hyrax-Management-Guide#analytics-and-usage-statistics for setup details.  Note that Hyrax seems to expect the .p12 file version of the private key, rather than the json version.

* Set up a cron job to import GA stats nightly

  Test the script to make sure that it can run successfully.  Make sure the script has execute permissions.  Your `analytics.yml` file must also be set up correctly in order for the script to succeed.

          cd /opt/scholarspace/scholarspace-hyrax/script
          sudo chmod +x import_stats.sh
          ./import_stats.sh production

  If it runs successfully, proceed with adding the cron job:

          crontab -e

  Add a line similar to the following:

        0 5 * * * /opt/scholarspace/scholarspace-hyrax/script/import_stats.sh production

### (NEEDS REFRESH - see [#11](https://github.com/gwu-libraries/scholarspace-hyrax/issues/11)) (Optional) Set up Shibboleth integration on the GW ScholarSpace server:

  Please refer to https://github.com/gwu-libraries/shibboleth for the recommended steps for setting up the Shibboleth integration.

* If Shibboleth has been setup on the GW ScholarSpace Server, enable Shibboleth in the appropriate environment file (ie: `config/environments/production.rb`):

         config.shibboleth = true

## Note about ghostscript and ImageMagick  

Hyrax can be ficky about versions of ghostscript and ImageMagick.  A working combination seems to be:  ghostscript 9.26 with ImageMagick 6.9.7-4

-----------------------------------------

# Installation with Docker (beta)

## Prerequisites

- An Ubuntu 20 instance. To date, we have not tested a successful development setup with Ubuntu 22,
though it may be more likely to succeed for a production setup.
- A `scholarspace` system account
- The following directories, owned by `scholarspace:scholarspace`:
  - `/opt/scholarspace`
  - `/opt/scholarspace/scholarspace-derivatives`
  - `/opt/scholarspace/scholarspace-tmp`
  - `/opt/scholarspace/scholarspace-minter`
- Installation of [Docker](https://docs.docker.com/engine/install/ubuntu/) and [docker-compose](https://docs.docker.com/compose/install/linux/#install-using-the-repository). Add the `scholarspace` user to the `docker` group in `/etc/group`.
- A clone of this repository, as `/opt/scholarspace/scholarspace-hyrax` (owned by `scholarspace`)
- `.env`, copied from `example.env`, with key values populated appropriately.
- For a new instance (not migrated)
  - Create `/var/solr/data` and assign ownership to `8983:8983`
- To use an existing core (migration), do the following (before starting the container):
  - Place a copy of the parent core directory (i.e., scholarspace) in `/var/solr/data` on the Docker host.
  - Grant ownership to the container's Solr user:  `chown -R 8983:8983 var/solr/data`
- For development:
   - The following system packages installed: `libxml2` `libxml2-dev`
   - [`rvm`](https://github.com/rvm/ubuntu_rvm), installed for the `scholarspace` user (via `sudo usermod -a -G rvm scholarspace`)
   - `rvm install ruby-2.7.3` (or whichever version is referenced in `Dockerfile`).  This will need to be run by a user who has `sudo` privileges.
   - `gem install bundler && bundle install --without development --deployment`

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
- The current version in production is 4.7.1. The Docker image is slightly ahead.
- The Docker image uses Jetty, not Tomcat. Configuring authenticatiomn for Jetty requires a different process, documented [here](https://wiki.lyrasis.org/display/FEDORA474/How+to+Configure+Servlet+Container+Authentication) and with examples in the `docker-fcrepo` repository. 


### Postgres
- Currently, separate postgres containers (each with their own Docker volume) are used for the Fedora and Rails databases. This may be desirable for migration purposes, i.e., if the two databases in production are running on different versions of postrgres. 
- The Rails/Hyrax postrgres container is using a version pinned to the version in use in production.


### Solr
- The Solr container is configured to run a script on startup that checks for the existence of a named Solr core (provided as an environment variable). 
- This image uses a base image that is one point release ahead of the version of Solr deployed in production (6.4.2 vs. 6.4.1). This is done to leverage a feature of the 6.4.2 image that facilitates implementation of the custom Hyrax schema. 
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

## Setting up the server

1. Install the [Docker engine](https://docs.docker.com/engine/install/ubuntu/).
2. Edit `/etc/group` and add your user (e.g., `ubuntu`) to the `docker` group.
3. For local development, 

  - sudo adduser --disabled-password scholarspace
  - Edit `/etc/group` and add your user to the `scholarspace` group.
  - Run `id scholarspace` and note the values for `uid` and `gid`. You'll want to add those to the `.env` file (see below).
4. Create an `opt/scholarspace` directory and clone the `scholarspace-hyrax` repository inside it. 
5. Create a directory for derivatives: `mkdir -p /opt/scholarspace/scholarspace-derivatives`.
  - For development, also create the following (empty) directories:
    ```
    /opt/scholarspace/certs 
    /opt/scholarspace/scholarspace-tmp 
    /opt/scholarspace/scholarspace-minter 
    ```
  - Then `chown -R scholarspace:scholarspace /opt/scholarspace/`.
6. In `/opt/scholarspace/scholarspace-hyrax` run `cp example.env .env` to create the local environment file.
7. Edit `.env` to add the following values:
  - SCHOLARSPACE_UID, SCHOLARSPACE_GID (if linking in external code for development)
  - HYRAX_DB_USER, HYRAX_DB_PASSWORD (for the Hyrax app database)
  - CONTACT_EMAIL
  - Variables under the `#Recaptch config` comment
  - RAILS_ENV and PASSENGER_APP_ENV (if other than production)
  - SMTP_USER and SMTP_PASSWORD
  - SERVER_NAME (hostname for Nginx)
  - SSL_ON (set to `true` if using)
  - `SSL_` variables (if using)
  - PERM_URL_BASE (used for persistent links)
  - FEDORA_PG_USER, FEDORA_PG_PASSWORD, FEDORA_USER, FEDORA_PASSWORD (username and password for the Fedora db backend and the Fedora app, respectively)
8. Adjust any other variables in the `.env` as needed.
9. Edit `docker-compose.yml` as necessary.
  - If running in development, change the volume mappings for the `sidekiq` and the `app-server` services and change the value for `POSTGRES_DB` under the `hyrax-pg` service definition.
10. If migrating data, prepare the Solr core and Fedora database locally (see below).
11. Start the application containers by running `docker compose up -d`. This will build the Hyrax app/Sidekiq and Solr images locally and start all containers.
12. If migrating data, restore the postgres database dumps for Fedora and Hyrax (see below).
13. The Hyrax server will not work without the value of `SECRET_KEY_BASE` being set in the `.env` file. To generate a secret key using Rails, run `docker exec -it --user scholarspace [app-server-container-name] bash -lc "docker/scripts/app-init.sh --create-secret"`. The `app-server-container-name` is probably `scholarspace-hyrax-app-server-1` but can be ascertained by running `docker ps`.
13. Add the secret key string to the `.env` file and restart the containers: `docker compose down && docker-compose up -d`.
14.  If migrating data, run the Rake job to perform database migrations: `docker exec -it --user scholarspace [app-server-container-name] bash -lc "docker/scripts/app-init.sh --run-migrations"`. 
  - If creating a new instance (no migrated data), run  `docker exec -it --user scholarspace [app-server-container-name] bash -lc "docker/scripts/app-init.sh --load-schema"`.
15. Visit the site in a web browser to trigger the Passenger app. (You won't see the compiled assets yet.)
16. Compile assets: `docker exec -it --user scholarspace [app-server-container-name] bash -lc "docker/scripts/app-init.sh --precompile-assets"`.
17. (Production only): Restart the Nginx server: `docker exec [app-container-name] bash -lc "passenger-config restart-app /"`. (In development mode, the `app-init.sh` script restarts the server by default after running any of the above options.)
18. The following additional steps may be useful in setting up a new instance (no migrated data), all of which can be run as options of the `app-init.sh` script:
  - `--create-roles`: create default app roles (if they don't already exist)
  - `--create-admin-set`: create the default Admin Set, if it doesn't already exist
  - `--add-admin-user`: grant a ScholarSpace user the `admin` role. To use: first, create the user in the ScholarSpace UI. Then run this command, inserting an environment variable (`admin_user=USER_EMAIL_ADDRESS`) before the path to the script. This environment variable will be used by the Rake task to look up the user in the app database. 
 - `--create-sitemap`: enqueue the Rake task to generate a sitemap. **This command should be run in the Sidekiq container, not the app server container.
 - You can string multiple options together, provided you **enclose the entire string, including the path to the script, in quotation marks**.

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

 ## Persistence

- As currently configured, `docker-compose.yml` uses Docker volumes to persist storage for the Postgres databases.
- The Solr and Fedora containers are mapped to local directories on the host (*bind mounts*, in Docker jargon). 


## Development tips

- The base image for the `app-server` image is derived from Ubuntu 20. When mapping the container to the external volume `opt/scholarspace`, which includes the project gems, I encountered a problem with the [ffi](https://github.com/ffi/ffi) gem, which depends on system C components, because my host machine was running Ubuntu 18. I resolved the issue by upgrading the host machine to Ubuntu 20 and reinstalling the project gems with `bundle install`.
- To avoid typing a long string whenever you want to access the Hyrax app container, you can assign an alias, in the `~/.bash_alias` file, using the `docker ps` command to identify the app container, like so:
`alias hyrax-container='docker exec -it --user scholarspace $(docker ps --filter "name=app" -q) bash -l'`
- Likewise, an alias to restart Passenger in the app container (in production): 
`alias restart-hyrax='docker exec $(docker ps --filter 'name=app' -q) bash -lc "passenger-config restart-app /"'` 
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

