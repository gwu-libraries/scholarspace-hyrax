# scholarspace-hyrax [![Build Status](https://travis-ci.org/gwu-libraries/scholarspace-hyrax.png?branch=master)](https://travis-ci.org/gwu-libraries/scholarspace-hyrax)

A Hyrax app for GW Libraries with:
- two item types: GwWork and GwEtd
- roles: admin, content-admin

Some convenient links to have handy:
- [Hyrax github repo](https://github.com/samvera/hyrax/)
- [Hyrax project](http://hyr.ax/)
- [scholarspace-sufia7 repo](https://github.com/gwu-libraries/scholarspace-sufia7/)

# Getting started

The recommended production setup involves two servers.  However, these can be the same server if needed, for example in a development environment.
- Repository server, for the Fedora repository and Solr interface
- Application server, for the GW ScholarSpace rails app

These instructions have been updated for Ubuntu 16.04.

# Repository server

* Install Java 8 for Ubuntu 16.04:
```
   % sudo add-apt-repository ppa:webupd8team/java
   % sudo apt-get update
   % sudo apt-get install oracle-java8-installer
```
   Verify that Java has been installed and is running Java 8:
```
   % java -version
```
   This should return Java version 1.8.
   
   Optionally, you can remove the installer using ```sudo add-apt-repository -r ppa:webupd8team/java```
   
* Install necessary Ubuntu packages:
```
   % sudo apt-get install git postgresql libpq-dev unzip clamav-daemon curl tomcat7 libcurl4-openssl-dev apache2-threaded-dev libapr1-dev libaprutil1-dev apache2-mpm-worker apache2-threaded-dev
```

* Create needed directories:
```
   % sudo mkdir /opt/install
   % sudo mkdir /opt/fedora; sudo chown tomcat7:tomcat7 /opt/fedora
   % sudo mkdir /etc/fcrepo
```

### Tomcat 7 setup

* Configure Tomcat7 Java settings:

  Retrieve ```tomcat_conf/tomcat7``` file from this github repository and overwrite ```/etc/default/tomcat7```
  
### Solr setup

* Install Solr:
```
  % cd /opt/install
  % wget http://archive.apache.org/dist/lucene/solr/6.4.1/solr-6.4.1.tgz
  % tar xzf solr-6.4.1.tgz solr-6.4.1/bin/install_solr_service.sh --strip-components=2
  % sudo ./install_solr_service.sh solr-6.4.1.tgz
```
* Verify that Solr started
```
  % sudo service solr status
```
(TODO: Is this needed any more, in light of below copy from samvera/hyrax/solr_config/conf??)
* Copy the solr/config folder contents from the scholarspace-hyrax repository to /opt/install/solr/config

* Configure a Solr core:
```
  % sudo su - solr -c "/opt/solr/bin/solr create -c scholarspace -n /opt/install/solr/config"
```  
  Convert the new Solr core from `managed-schema` to `schema.xml` support:
```  
  % sudo mv /var/solr/data/scholarspace/conf/managed-schema /var/solr/data/scholarpsace/conf/managed-schema.bak
```  
  Copy the `solr_config/conf` contents from the samvera/hyrax repo to `/var/solr/data/scholarspace/conf/`
  
  Restart Solr:
```  
  % sudo service solr restart
``` 
### Set up Fedora with audit support
```
   % cd /opt/install
   % wget https://github.com/fcrepo4-exts/fcrepo-webapp-plus/releases/download/fcrepo-webapp-plus-4.7.1/fcrepo-webapp-plus-audit-4.7.1.war
   % sudo cp fcrepo-webapp-plus-audit-4.7.1.war /var/lib/tomcat7/webapps/fcrepo.war
```   
   Wait for tomcat to deploy the war file before proceeding to the next step.  This can be verified by watching `/var/log/tomcat7/catalina.out`
   
   Copy the `tomcat_conf/fcrepo-webapp/web.xml` file from the Github repo to `/var/lib/tomcat7/webapps/fcrepo/WEB-INF/web.xml` 
   
   Ensure that tomcat7 library files are all still owned by tomcat7
```
   % sudo chown -R tomcat7:tomcat7 /var/lib/tomcat7
```
   Set up Fedora authentication by copying the `tomcat_conf/tomcat-users.xml` file from the Github repo and overwrite `/etc/tomcat7/tomcat-users.xml`.   Edit `tomcat-users.xml` and replace the dummy passwords with your preferred secure passwords.  (Be sure that your passwords don't contain any characters considered special characters in XML, such as `<`,`>`,`&`,`'`,`"`)

* OPTIONAL: (If creating a new repository, skip this step) Create a backup of the existing Fedora instance
```
    % sudo mkdir /opt/fedora_backups
    % sudo chown -R tomcat7:tomcat7 /opt/fedora_backups
    % curl -X POST -u <FedoraUsername>:<FedoraPassword> --data "/opt/fedora_backups" yourserver.com/fcrepo/rest/fcr:backup
```
   Verify that a backup was created in `/opt/fedora_backups` before proceeding

## Set up a PostgreSQL database for Fedora

* Create a postgreSQL database user and database for Fedora
```
   % sudo su - postgres
   (postgres)% psql
   postgres=# create user YOURDBUSERNAME with createdb password 'YOURDBPASSWORD';
   postgres=# \q
   (postgres)% createdb -O YOURDBUSERNAME ispn
   (postgres)% exit
```
Note the database name for Fedora must be `ispn`

* Create a Fedora settings folder
```
   % sudo mkdir /etc/fcrepo
   % sudo chown -R tomcat7:tomcat7 /etc/fcrepo
```   
* Copy `tomcat_conf/fcrepo/infinispan.xml` from the Github repo to `/etc/fcrepo/infinispan.xml`.  Edit `infinispan.xml` and replace the database username and password with the database username and password created above.

* Restart Tomcat
```
   % sudo service tomcat7 restart
```

* OPTIONAL:  To restore from a Fedora backup:
```
   % curl -X POST -u <FedoraUsername>:<FedoraPassword> --data "/opt/fedora_backups" yourserver.com/fcrepo/rest/fcr:restore
```
   Restart tomcat and validate that the repository has been restored:
```
   % sudo service tomcat7 restart
```

### Optional: Add SSL to Fedora Connections
These instructions are for redirecting port 8080 traffic on Tomcat to port 8443 and running SSL using the Apache Portable Runtime (APR).

* Install Tomcat dependencies
```  
        % sudo apt-get install libapr1 libapr1-dev libtcnative-1
```
*  Add the `tomcat7` user to the `ssl-cert` group in `/etc/group`
```
        % sudo vi /etc/group
```
*  Generate your SSL certificates and key using the instructions provided here: https://github.com/gwu-libraries/ssl_howto

*  Update the `server.xml` file
```
        % cd /opt/install
        Retrieve `server_ssl.xml` from `tomcat_conf/server_ssl.xml` in the GitHub repo
        % sudo cp tomcat_conf/server_ssl.xml /etc/tomcat7/server.xml
```        
*  Edit `/etc/tomcat/server.xml` and replace the dummy values for the following lines with your certificates and keys:
	```
        SSLCertificateFile="/etc/ssl/certs/yourservername.cer"
        SSLCertificateChainFile="/etc/ssl/certs/yourservername.cer"
        SSLCertificateKeyFile="/etc/ssl/private/yourservername.pem"
	```
*  Create a symbolic link to `libtcnative1.so` to address a Ubuntu/Tomcat bug
```        
        % sudo ln -sv /usr/lib/x86_64-linux-gnu/libtcnative-1.so /usr/lib/
```
*  Replace the `web.xml` files for Fedora with the `web_ssl.xml` files from the repo:
```
        % cd /opt/install
```
   Retrieve `web_ssl.xml` from `tomcat_conf/fcrepo-webapp/web_ssl.xml` in the GitHub repo
```
        % cp tomcat_conf/fcrepo-webapp/web_ssl.xml /var/lib/tomcat7/webapps/fcrepo/WEB-INF/web.xml
```
*  Restart Tomcat and test access over HTTPS
```
        % sudo service tomcat7 restart
```

# Application server

### Install ependencies

* Install necessary Ubuntu packages:
```
        % sudo apt-get update
        % sudo apt-get install git postgresql libpq-dev redis-server unzip clamav-daemon curl imagemagick libapache2-mod-shib2  libreoffice libcurl4-openssl-dev apache2-mpm-worker apache2-threaded-dev 
```
* Install RVM for multi-users
```
        % curl -L https://get.rvm.io | sudo bash -s stable
        % source ~/.rvm/scripts/rvm
        % rvm install ruby-2.3.3
```        

* Install Rails:
```
        % gem install rails -v 5.0.4 -N
```      
* Create directories
```
        % mkdir /opt/scholarspace
        % mkdir /opt/install
        % mkdir /opt/xsendfile
```       
* Create the necessary users and user groups, and assign folder permissions
```
        % sudo adduser --disabled-password scholarspace
```        
        This also creates a `scholarspace` group.  Edit `/etc/group` and add users (including www-data) to the new `scholarspace` group.  Additionally, add the scholarspace user to the `rvm` group.
```        
        % sudo chown scholarspace:scholarspace /opt/scholarspace
        % sudo chown www-data:www-data /opt/xsendfile
```
* Get the GW ScholarSpace code:
```
        % cd /opt/scholarspace
        % git clone https://github.com/gwu-libraries/scholarspace-hyrax.git
```
  Check out the desired tag, where `TAGNUMBER` might be, for example, `1.0`:
```
        % git checkout TAGNUMBER
```

* Install gems
```
        % cd scholarspace-hyrax
        % bundle install --without development --deployment
```	
	More information on the meaning of these bundle install options can be found at http://bundler.io/v1.15/man/bundle-install.1.html .  For a development environment, to install development gems as well, omit the `--without development` option.

* Create a postgresql user for scholarspace
```
        % sudo su - postgres
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
* Create the `database.yml` file
```
        % cd config
        % cp database.yml.template database.yml
```
  Edit `database.yml` to add your specific database names and credentials

* Create the `solr.yml` file
```
        % cd config
        % cp solr.yml.template solr.yml
```
  Edit `solr.yml` to add your specific names and credentials

* Create the `blacklight.yml` file
```
        % cd config
        % cp blacklight.yml.template blacklight.yml
```
  Edit `blacklight.yml` to add your specific names and credentials

* Create the `fedora.yml` file
```
        % cd config
        % cp fedora.yml.template fedora.yml
```
  Edit `fedora.yml` to add your specific Fedora repository names and credentials

* Create the secure secret key. In production, put this in your environment, not in the file.
```
        % cd config
        % cp secrets.yml.template secrets.yml
        % rake secret
```
  Paste the secret key into the `secrets.yml` file (for dev and test)

* Run the database migrations
```
        % rake db:migrate RAILS_ENV=production
```
* Install `fits.sh` version 1.0.5 (check [FITS](http://projects.iq.harvard.edu/fits/downloads) for the latest 1.0.5 download).  Also check the [Hyrax repo](https://github.com/samvera/hyrax/#prerequisites) to verify the latest recommended version of FITS for use with Hyrax.
```
        % cd /usr/local/bin
        % sudo curl http://projects.iq.harvard.edu/files/fits/files/fits-1.0.5.zip -o fits-1.0.5.zip
        % sudo unzip fits-1.0.5.zip
        % cd fits-1.0.5
        % sudo chmod a+x fits*.sh
```

### Configure the `minter-state` file path

  * Create a minter folder
```
        % sudo mkdir /opt/scholarspace/scholarspace-minter
        % sudo chown -R scholarspace:scholarspace /opt/scholarspace/scholarspace-minter
```
    If an existing `minter-state` file exists in `/tmp/minter-state` copy it to the new folder
```        
        % cp /tmp/minter-state /opt/scholarspace/scholarspace-minter/
```
    Uncomment `config.minter_statefile` in `config/initializers/hyax.rb`
```
         config.minter_statefile = '/opt/scholarspace/scholarspace-minter/minter-state'
```

### Configure the tmp path
  
  * Create a tmp folder  
```
        % sudo mkdir /opt/scholarspace/scholarspace-tmp
        % sudo chown -R scholarspace:scholarspace /opt/scholarspace/scholarspace-tmp
```
  * Uncomment `config.temp_file_base` in `config/initializers/hyrax.rb`
```
         config.temp_file_base = '/opt/scholarspace/scholarspace-tmp'
```
### Configure max days between audits

  * Uncomment `config.max_days_between_audits` in `config/initializers/hyrax.rb`
```
         config.max_days_between_audits = 7
```

### Configure path for libre-office

  * Uncomment `config.libreoffice_path` in `config/initializers/hyrax.rb`
```
         config.libreoffice_path = "/usr/bin/soffice"
```
### Configure derivatives path for Sufia

   * Create a derivatives folder on your application server:
```
         % sudo mkdir /opt/scholarspace/scholarspace-derivatives
         % sudo chown -R scholarspace:scholarspace /opt/scholarspace/scholarspace-derivatives
```	 
   * Add `config.derivative_path` to `config/initializers/hyrax.rb`
```
         config.derivative-path = "/opt/scholarspace/scholarspace-derivatives/"
```

### Configure Contact form emailing

  In order to enable the contact form page to send email when the user clicks Send,
set the following properties in `config/initializers/sufia.rb` :
```
         config.contact_email = 
```

  * Create a `setup_mail.rb` file 
```
    % cp config/initializers/setup_mail.rb.template config/initializers/setup_mail.rb
```

  Set the SMTP credentials for the user as whom the app will send email.  Make sure that the `user_name` value in `setup_mail.rb` matches the `contact_email` value configured above in `sufia.rb`.
  
  * Edit `config/initializers/mailboxer.rb` with email account from which to send messages and notifications:
```
         config.default_from = 
```
   
# ***RESUME EDITING HERE***

### Make files in `script` executable:

         chmod -R a+x script

### Start a Redis RESQUE pool

        % script/restart_resque.sh production

### Create the user roles

  Run the rake task that creates user roles called `admin` and `content-admin`:

        % rake gwss:create_roles RAILS_ENV=production

  At the rails console, add an initial user to the `admin` role.  Make sure that your admin user
has logged in at least once.

        % rails c
        > r = Role.find_by_name('admin')
        > r.users << User.find_by_user_key('YOUR_ADMIN_USER_EMAIL@gwu.edu')
        > r.save 

  We will [add the content-admin users](#prod-add-content-admin) later through the /roles UI.

### (Optional) Populate the initial content blocks

  Run the rake task that takes the content of the HTML files in config/locales/content_blocks and populates the associated content blocks.  Note that for an existing instance, running this rake task will overwrite any chnages you've made to the content blocks!

        % rake gwss:populate_content_blocks RAILS_ENV=production

### Configure Passenger and Apache2

* Set up Passenger

        % gem install passenger -v 5.0.19
        % passenger-install-apache2-module
        Select Ruby from the list of languages
        
* Configure Apache for Passenger

        % cd /opt/install
        Retrieve `passenger.conf` from  `apache2_conf/passenger.conf` in the GitHub repo
        % sudo cp apache2_conf/passenger.conf /etc/apache2/conf-available/passenger.conf
   
* Enable the `passenger.conf` file and the rewrite Apache mod

        % sudo a2enconf passenger.conf
        % sudo a2enmod rewrite
        % sudo service apache2 restart

* Create and enable an Apache2 virtual host

        % cd /opt/install
        Retrieve `scholarspace.conf` from `apache2_conf/scholarspace.conf` in the GitHub repo
        Retrieve `scholarspace-ssl.conf` from `apache2_conf/scholarspace-ssl.conf` in the GitHub repo
        % sudo cp apache2_conf/scholarspace.conf /etc/apache/sites-available/scholarspace.conf
        % sudo cp apache2_conf/scholarspace-ssl.conf /etc/apache/sites-available/scholarspace-ssl.conf

  Enable modssl

        % sudo a2enmod ssl

  Generate certificates and place them in paths referenced in `scholarspace-ssl.conf` (modify the paths in `scholarspace-ssl.conf` if needed).  Cert file names should also match.
  
        % sudo a2dissite 000-default.conf
        % sudo a2ensite scholarspace.conf
        % sudo a2ensite scholarspace-ssl.conf
        
* Install `mod_xsendfile` (on the GW Scholarspace application server, if deploying on separate servers)

        % cd /opt/install
        % git clone https://github.com/nmaier/mod_xsendfile.git
        % cd mod_xsendfile
        % sudo apxs2 -cia mod_xsendfile.c
        % sudo service apache2 restart

### Final Deployment

* Prepare databases and assets for production

        % cd /opt/scholarspace
        % rake assets:precompile RAILS_ENV=production 
        % sudo service apache2 restart
        
### (Optional) Set up Shibboleth integration on the GW ScholarSpace server:

  Please refer to https://github.com/gwu-libraries/shibboleth for the recommended steps for setting up the Shibboleth integration.

* If Shibboleth has been setup on the GW ScholarSpace Server, enable Shibboleth in the appropriate environment file (ie: `config/environments/production.rb`):

         config.shibboleth = true

### (Optional) Add content-admin users <a id="prod-add-content-admin"></a>

* Ask each of the content-admin users to log in to the application at least once.  Right now they will have read-only rights.

* Log in as an admin user, and navigate to /roles

* Select the content-admin role, and add each of the users to whom you wish to grant content-admin rights.  These users should now be able
to upload items and edit the items that they have uploaded (plus items transferred or proxied to them).

* Note that removing users from roles through the /roles interface is currently broken, and must be accomplished through the rails console.

### (Optional) Enable weekly file audits

 * Uncomment the following line in `config/initializers/sufia.rb`
 
         config.max_days_between_audits = 7

### (Optional) Enable citation pages

 * Uncomment the following line in `config/initializers/sufia.rb` and set to `true`
 
         config.citations = true

### (Optional) Enable office document derivatives

 * Uncomment the following line in `config/initializers/sufia.rb`
 
         config.libreoffice_path = "soffice"

### (Optional) Add Google Analytics

* Enable Google Analytics in `config/initializers/sufia.rb` by editing the following lines:

         # Enable displaying usage statistics in the UI
         # Defaults to FALSE
         # Requires a Google Analytics id and OAuth2 keyfile.  See README for more info
         config.analytics = true
        
         # Specify a Google Analytics tracking ID to gather usage statistics
         config.google_analytics_id = 'UA-99999999-1'

         # Specify a date you wish to start collecting Google Analytic statistics for.
         config.analytic_start_date = DateTime.new(2015,11,10)

* Copy the `analytics.yml.template` file in config

        % cp config/analytics.yml.template config/analytics.yml

* Populate the `analyitcs.yml` file with your Google Analyitcs credentials.  See: https://github.com/projecthydra/sufia#analytics-and-usage-statistics for setup details.  Note that sufia seems to expect the .p12 file version of the private key, rather than the json version.

* Set up a cron job to import GA stats nightly

  Test the script to make sure that it can run successfully.  Make sure the script has execute permissions.  Your `analytics.yml` file must also be set up correctly in order for the script to succeed.

        % cd /opt/scholarspace/script
        % sudo chmod +x import_stats.sh
        % ./import_stats.sh production

  If it runs successfully, proceed with adding the cron job:

        % crontab -e

  Add a line similar to the following:

        0 5 * * * /opt/scholarspace/script/import_stats.sh production

