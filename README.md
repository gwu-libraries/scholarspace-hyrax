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

Currently these instructions are for an Ubuntu 16.04 repository server, and an Ubuntu 18.04 application server.

# Repository server

* Install Java 8

  - For Ubuntu 16:
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
      sudo apt-get install git postgresql libpq-dev unzip clamav-daemon curl tomcat7 libcurl4-openssl-dev libapr1-dev libaprutil1-dev
  ```

* Create needed directories:
  ```
    sudo mkdir /opt/install
    sudo mkdir /opt/fedora; sudo chown tomcat7:tomcat7 /opt/fedora
    sudo mkdir /etc/fcrepo
  ```

## Tomcat 7 setup

* Configure Tomcat7 Java settings:

  Retrieve ```tomcat_conf/tomcat7``` file from this github repository and overwrite ```/etc/default/tomcat7```
  
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
* Copy the `solr/config/` contents from the [samvera/hyrax repo](https://github.com/samvera/hyrax/tree/v2.0.3/solr/config) to `/var/solr/data/scholarspace/conf/` (this can be accomplished by git clone-ing the hyrax repo, making sure to check out the appropriate tag)

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
      sudo chown -R tomcat7:tomcat7 /opt/fedora_backups
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

   Edit `/etc/default/tomcat7` and update these settings with the ispn database username and password, replacing the
   placeholders for these values:

  ```
    JAVA_OPTS="${JAVA_OPTS} -Dfcrepo.postgresql.username=<ADD ISPN DB USERNAME HERE>"
    JAVA_OPTS="${JAVA_OPTS} -Dfcrepo.postgresql.password=<ADD ISPN DB PASSWORD HERE>"
  ```

### Create a Fedora settings folder
  ```
    sudo mkdir /etc/fcrepo
  ```
* Copy `tomcat_conf/fcrepo/infinispan.xml` from the Github repo to `/etc/fcrepo/infinispan.xml`.  Set the ownership to tomcat7:

  ```
    sudo chown -R tomcat7:tomcat7 /etc/fcrepo
  ``` 

### Set up Fedora with audit support

* Copy fcrepo WAR file to tomcat7
  ```
    cd /opt/install
    wget https://github.com/fcrepo4-exts/fcrepo-webapp-plus/releases/download/fcrepo-webapp-plus-4.7.1/fcrepo-webapp-plus-audit-4.7.1.war
    sudo cp fcrepo-webapp-plus-audit-4.7.1.war /var/lib/tomcat7/webapps/fcrepo.war
  ```
* Wait for tomcat to deploy the war file before proceeding to the next step.  This can be verified by watching `/var/log/tomcat7/catalina.out`
   
* Copy the `tomcat_conf/fcrepo-webapp/web.xml` file from the Github repo to `/var/lib/tomcat7/webapps/fcrepo/WEB-INF/web.xml` 
   
* Ensure that tomcat7 library files are all still owned by tomcat7
  ```
    sudo chown -R tomcat7:tomcat7 /var/lib/tomcat7
  ```
* Set up Fedora authentication by copying the `tomcat_conf/tomcat-users.xml` file from the Github repo and overwrite `/etc/tomcat7/tomcat-users.xml`.   Edit `tomcat-users.xml` and replace the dummy passwords with your preferred secure passwords.  (Be sure that your passwords don't contain any characters considered special characters in XML, such as `<`,`>`,`&`,`'`,`"`)
   
* Edit `/var/lib/tomcat7/webapps/fcrepo/WEB-INF/classes/config/jdbc-postgresql/repository.json` to change the database name from `fcrepo` to `ispn`.

* Restart Tomcat
  ```
    sudo service tomcat7 restart
  ```
  Check `/var/log/tomcat7/catalina.out` to ensure that tomcat7 restarted and deployed fcrepo with no errors.


* OPTIONAL:  To restore from a Fedora backup:
  ```
    curl -X POST -u <FedoraUsername>:<FedoraPassword> --data "/opt/fedora_backups" yourserver.com/fcrepo/rest/fcr:restore
  ```
    Restart tomcat and validate that the repository has been restored:
  ```
    sudo service tomcat7 restart
  ```

### Optional: Add SSL to Fedora Connections
These instructions are for redirecting port 8080 traffic on Tomcat to port 8443 and running SSL using the Apache Portable Runtime (APR).

* Install Tomcat dependencies
  ```
         sudo apt-get install libapr1 libapr1-dev libtcnative-1
  ```

* Add the `tomcat7` user to the `ssl-cert` group in `/etc/group`
  ```
          sudo vi /etc/group
  ```
*  Generate your SSL certificates and key using the instructions provided here: https://github.com/gwu-libraries/ssl_howto

*  Update the `server.xml` file

           cd /opt/install

    Retrieve `server_ssl.xml` from `tomcat_conf/server_ssl.xml` in the GitHub repo:

           sudo cp tomcat_conf/server_ssl.xml /etc/tomcat7/server.xml

* Edit `/etc/tomcat7/server.xml` and replace the dummy values for the following lines with your certificates and keys:
	```
        SSLCertificateFile="/etc/ssl/certs/yourservername.cer"
        SSLCertificateChainFile="/etc/ssl/certs/yourservername.cer"
        SSLCertificateKeyFile="/etc/ssl/private/yourservername.pem"
	```
* Create a symbolic link to `libtcnative1.so` to address a Ubuntu/Tomcat bug
  ```
          sudo ln -sv /usr/lib/x86_64-linux-gnu/libtcnative-1.so /usr/lib/
  ```
* Replace the `web.xml` files for Fedora with the `web_ssl.xml` files from the repo:
  ```
          cd /opt/install
  ```
  Retrieve `web_ssl.xml` from `tomcat_conf/fcrepo-webapp/web_ssl.xml` in the GitHub repo
  ```
          cp tomcat_conf/fcrepo-webapp/web_ssl.xml /var/lib/tomcat7/webapps/fcrepo/WEB-INF/web.xml
  ```
  *  Restart Tomcat and test access over HTTPS
  ```
          sudo service tomcat7 restart
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
          gem install rails -v 5.2.6 -N
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

### Configure Passenger and Apache2

* Set up Passenger, and create Passenger config for Apache
  ```
          gem install passenger -v 6.0.9
          rvmsudo passenger-install-apache2-module
  ```
   Select Ruby from the list of languages.  The install script will direct you to copy several lines for the Apache configuration.  They will look something similar to:
  ```  
  LoadModule passenger_module /usr/local/rvm/gems/ruby-2.7.3/gems/passenger-6.0.9/buildout/apache2/mod_passenger.so
  <IfModule mod_passenger.c>
    PassengerRoot /usr/local/rvm/gems/ruby-2.7.3/gems/passenger-6.0.9
    PassengerDefaultRuby /usr/local/rvm/gems/ruby-2.7.3/wrappers/ruby
  </IfModule>
  ```
  Create `/etc/apache2/conf-available/passenger.conf` using the lines pasted from the Passenger install script.

  Add the following line into `passenger.conf`:

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
  Use the output provided by `whenever` to create a cron job.  A recommended approach is to (as the `scholarspace` user, run `crontab -e` to edit the cron jobs.  Your crontab might include a job that looks like this:
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
