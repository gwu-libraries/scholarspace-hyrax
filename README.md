# scholarspace-sufia7
A nearly-vanilla sufia7 app with the potential to be built out as GW ScholarSpace 2.0

## Install prerequisites

* Install RVM (follow instructions at rvm.io), then `source .bashrc` (or log out and log back in)

* Install Ruby:
```
    rvm install ruby-2.3
```
* Install rails
* (if this fails you can install from the steps at https://rvm.io/rvm/install)
```
    gem install rails -v 4.2.6
```
* Install Java 8 (use below or follow directions in scholarspace repo)
```
    % sudo apt-add-repository ppa:webupd8team/java
    % sudo apt-get update
    % sudo apt-get install oracle-java8-installer
    % sudo apt-get install oracle-java8-set-default
```
* Install apt packages
```
    sudo apt-get install imagemagick libreoffice git redis-server unzip
```
* Install fits-0.8.5 (follow directions in scholarspace repo, be sure to change version number to 0.8.5)

* Clone this repo
```
    cd /opt
    sudo mkdir scholarspace
    sudo chown MYUSER:MYGROUP scholarspace
    cd scholarspace
    git clone https://github.com/gwu-libraries/scholarspace-sufia7.git
```
   Make sure that `config.fits_path` in `config/initializers/sufia.rb` is set consistent with where you installed fits.  If not, update it.
    
* Install gems
```
    cd scholarspace-sufia7
    bundle install
```
* If you don't have a separate Solr and Fedora, use the packaged hydra-jetty (you may want to run these with nohup and/or in the background):
```
   mkdir tmp
   solr_wrapper -d solr/config/ --collection_name hydra-development
```
   You can check to see if Solr is started by going to port 8983 on your server.
```
   fcrepo_wrapper -p 8984
   OR
   nohup fcrepo_wrapper -p 8984 &
```
   You can check to see if Fedora is started by going to port 8984 on your server.

* Start the rails server

   For development purposes, you can run using `rails s` (shortcut for `rails server`):
```
    rails s -b 0.0.0.0
    OR
    nohup rails s -b 0.0.0.0 &
```
   The app will run on port 3000.  (To run on a different port, specify with the `-p` option.)
   
   If you get an error about a pending migration follow the suggested solution:
```
   bin/rake db:migrate RAILS_ENV=development
```

Installation with Apache, Tomcat 7, and Passenger <a id="prod-install"></a>
------------
Note: Solr, Fedora, PostgreSQL and the GW ScholarSpace application can all be deployed on different servers if desired.  If doing so, ensure that firewall ports are opened between the necessary servers and the GW ScholarSpace application server.

### Dependencies

* Install ubuntu 14.04 LTS package dependencies:

        % sudo apt-get update
        % sudo apt-get install git postgresql libpq-dev redis-server unzip clamav-daemon curl imagemagick libapache2-mod-shib2 tomcat7 libreoffice libcurl4-openssl-dev apache2-threaded-dev libapr1-dev libaprutil1-dev apache2-mpm-worker apache2-threaded-dev

* Install Java 8 for 14.04 (on the Solr/Fedora server):

        % sudo apt-add-repository ppa:webupd8team/java
        % sudo apt-get update
        % sudo apt-get install oracle-java8-installer
        % sudo apt-get install oracle-java8-set-default
        % sudo apt-get install subversion
       
* Install RVM for multi-users (for installation via SSL and other RVM installation information, refer to https://rvm.io/rvm/install) Installs RVM to /usr/local/rvm

   On the GW ScholarSpace server:

        % curl -L https://get.rvm.io | sudo bash -s stable
        % source ~/.rvm/scripts/rvm
        % rvm install ruby-2.2.1
        % sudo nano /etc/group
        
        Add users to the rvm group

* (Optional) Set up Shibboleth integration on the GW ScholarSpace server:

  Please refer to https://github.com/gwu-libraries/shibboleth for the recommended steps for setting up the Shibboleth integration.

* If Shibboleth has been setup on the GW ScholarSpace Server, enable Shibboleth in the appropriate environment file (ie: config/environments/production.rb):

	config.shibboleth = true

* Install Rails on the GW ScholarSpace server:

        % gem install rails -v 4.2.6 -N
        
* Create the directory structure

  On the GW ScholarSpace server:

        % mkdir /opt/scholarspace
        % mkdir /opt/install
        % mkdir /opt/xsendfile
        
  On the Solr/Fedora server (if deploying on a separate server - otherwise on the same server):
        
        % mkdir /opt/install
        % mkdir /opt/solr
        % mkdir /opt/fedora
        % sudo mkdir /var/log/solr
        
* Create the necessary user groups and assign folder permissions

  On the GW ScholarSpace server:

        % sudo groupadd scholarspace
        
        Edit /etc/group and add users (including www-data) to the new group
        
        % sudo chown $USER:scholarspace /opt/scholarspace
        % sudo chown www-data:www-data /opt/xsendfile
        
* Set up tomcat7 (on the Solr/Fedora server)

  Replace the /etc/default/tomcat7 file with the tomcat7 file from the /tomcat_conf folder in this repo.  This will set solr home, fcrepo home, and java path.

  Set the owner of the /opt/fedora directory:
        
        % sudo chown tomcat7:tomcat7 /opt/fedora

* Set up Solr (on the Solr server)

        % cd /opt/install
        % wget http://apache.claz.org/lucene/solr/6.2.0/solr-6.2.0.tgz
        % tar xzf solr-6.2.0.tgz solr-6.2.0/bin/install_solr_service.sh --strip-components=2
        % sudo ./install_solr_service.sh solr-6.2.0.tgz

  Verify Solr is running:

        % sudo service solr status
        
  Copy the solr/config folder from the repository to /opt/install
  
  	% svn checkout https://github.com/gwu-libraries/scholarspace-sufia7/trunk/solr

  Configure a Solr Core:

        % sudo su - solr -c "/opt/solr/bin/solr create -c scholarspace -n /opt/install/solr/config"
        
* Set up fcrepo with audit support

        % cd /opt/install
        % wget https://github.com/fcrepo4-exts/fcrepo-webapp-plus/releases/download/fcrepo-webapp-plus-4.5.1/fcrepo-webapp-plus-audit-4.5.1.war
        % cp fcrepo-webapp-plus-audit-4.5.1.war /var/lib/tomcat7/webapps/fcrepo.war

  Replace the web.xml file in /var/lib/tomcat7/webapps/fcrepo/WEB-INF/web.xml with the one from the tomcat_conf/fcrepo-webapp folder in the repo

* Ensure tomcat7 library files are (still) all owned by tomcat7

        % sudo chown -R tomcat7:tomcat7 /var/lib/tomcat7

* Set up authentication to fcrepo

        % cd /etc/tomcat7
        
  Replace tomcat-users.xml with the tomcat-users.xml file from tomcat_conf folder in the repo.
  
  Edit tomcat-users.xml and replace the "dummypasswords" with your secure passwords.
  
* Install postgresql on the Tomcat Server

        % sudo apt-get install postgresql

* Create of backup of the existing Fedora instance (If one exists)

        % sudo mkdir /opt/fedora_backups
        % sudo chown -R tomcat7:tomcat7 /opt/fedora_backups
        % curl -X POST -u <FedoraUsername>:<FedoraPassword> --data "/opt/fedora_backups" yourserver.com/fcrepo/rest/fcr:backup

Verify that a backup was created in /opt/fedora_backups before proceeding

* Create a postgresSQL database user for Fedora

        % sudo su - postgres
        (postgres)% psql
        postgres=# create user YOURDBUSERNAME with createdb password 'YOURDBPASSWORD';

* Create a postgresSQL database for Fedora

        postgres=# \q
        (postgres)% createdb -O YOURDBUSERNAME ispn
        (postgres)% exit
Note the database name for Fedora must be 'ispn'

* Create a Fedora settings folder

        % sudo mkdir /etc/fcrepo
        % sudo chown -R tomcat7:tomcat7 /etc/fcrepo

* Copy the infinispan.xml file from the repo

        % cp infinispan.xml /etc/fcrepo/infinispan.xml
Edit this file with your database username and database password

* Restart Tomcat

        % sudo service tomcat7 restart

* Restore the Fedora Backup (If a previous Fedora repository was running on LevelDB)

        % curl -X POST -u <FedoraUsername>:<FedoraPassword> --data "/opt/fedora_backups" yourserver.com/fcrepo/rest/fcr:restore
Validate that the repository has been restored

* Restart Tomcat7 Server

        % sudo service tomcat7 restart

### Install the GW ScholarSpace app:

On the GW ScholarSpace server:

* Get the GW ScholarSpace code:

        % git clone https://github.com/gwu-libraries/scholarspace.git

* Install gems

        % cd scholarspace
        % bundle install --without development --deployment

* Create a postgresql user

        % sudo su - postgres
        (postgres)% psql
        postgres=# create user YOURDBUSERNAME with createdb password 'YOURSFMDBPASSWORD';

  The result should be:

        CREATE ROLE

* Create three databases (e.g. scholarspace_dev, scholarspace_test, scholarspace_prod)

        postgres=# \q
        (postgres)% createdb -O YOURDBUSERNAME YOURDEVDBNAME
        (postgres)% createdb -O YOURDBUSERNAME YOURTESTDBNAME
        (postgres)% createdb -O YOURDBUSERNAME YOURPRODDBNAME
        (postgres)% exit

* Create the database.yml file

        % cd config
        % cp database.yml.template database.yml

  Edit database.yml to add your specific database names and credentials

* Create the solr.yml file

        % cd config
        % cp solr.yml.template solr.yml

  Edit solr.yml to add your specific names and credentials

* Create the blacklight.yml file

        % cd config
        % cp blacklight.yml.template blacklight.yml

  Edit blacklight.yml to add your specific names and credentials

* Create the fedora.yml file

        % cd config
        % cp fedora.yml.template fedora.yml

  Edit fedora.yml to add your specific Fedora repository names and credentials

* Create the secure secret key.  In production, put this in your environment, not in the file.

        % cd config
        % cp secrets.yml.template secrets.yml
        % rake secret

  Paste the secret key into the secrets.yml file (for dev and test)

* Run the database migrations

        % rake db:migrate RAILS_ENV=production
        
* Download the hydra-jetty jar files.  While we won't be running Solr and Fedora from hydra-jetty, we need to copy some of the jar files to the Solr deployment in order for full text indexing to work.
 
        % rake sufia:jetty:config

* Move the extraction .jar files from hydra-jetty to your Solr instance (needed for full text indexing)

  If your Solr instance is on the same server as the GW ScholarSpace application, replace the ``/opt/solr/contrib/extraction`` folder with a copy of ``/opt/scholarspace/jetty/solr/lib/contrib/extraction``:
        
        % rm -rf /opt/solr/contrib/extraction
        % cp -R jetty/solr/lib/contrib/extraction /opt/solr/contrib/
        % sudo service tomcat7 restart

  If your Solr instance is on a different server from the GW ScholarSpace application do the following:

  Download the /opt/scholarspace/jetty/solr/lib/contrib/extraction folder from the GW ScholarSpace application server via SFTP.

  On the Solr server, remove the /opt/solr/contrib/extraction directory that was installed with Solr 4.10.4:
        
        % rm -rf /opt/solr/contrib/extraction
        
  Upload the extraction folder from hydra-jetty to the server with your Solr instance into: /opt/solr/contrib/
        
        % sudo service tomcat7 restart
        
* On the GW ScholarSpace server, install fits.sh version 0.6.2 (check [FITS](http://projects.iq.harvard.edu/fits/downloads) for the latest 0.6.2 download)

        % cd /usr/local/bin
        % sudo curl http://projects.iq.harvard.edu/files/fits/files/fits-0.6.2.zip -o fits-0.6.2.zip
        % sudo unzip fits-0.6.2.zip
        % cd fits-0.6.2
        % sudo chmod a+x fits*.sh

### Configure ImageMagick policies

* On the GW ScholarSpace server, copy imagemagick_conf/policy.xml to /etc/ImageMagick (overwrite the default policy.xml)

### Configure the minter-state file path

  * Create a minter folder

        % sudo mkdir /opt/scholarspace/scholarspace_minter
        % sudo chown -R scholarspace_user:scholarspace_group /opt/scholarspace/scholarspace_minter

  * If an existing minter-state file exists in /tmp/minter-state copy it to the new folder
        
        % cp /tmp/minter-state /opt/scholarspace/scholarspace_minter/

  * Uncomment config.minter_statefile in config/initializers/sufia.rb

        # config.minter_statefile = '/opt/scholarspace/scholarspace_minter/minter-state'

### Configure the tmp path
  
  * Create a tmp folder  

        % sudo mkdir /opt/scholarspace/scholarspace_tmp
        % sudo chown -R scholarspace_user:scholarspace_group /opt/scholarspace/scholarspace_tmp

  * Uncomment config.temp_file_base in config/initializers/sufia.rb

        # config.temp_file_base = '/opt/scholarspace/scholarspace_tmp'

### Configure Contact form emailing

  In order to enable the contact form page to send email when the user clicks Send,
set the following properties in config/initializers/sufia.rb :
  * config.contact_email
  * config.from_email

Copy config/initializers/setup_mail.rb.template to config/initializers/setup_mail.rb .
Set the SMTP credentials for the user as whom the app will send email.

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
        
* Edit Apache for Passenger

  Copy the passenger.conf file from /opt/scholarspace/apache2_conf folder to /etc/apache2/conf-available/passenger.conf
   
* Enable the passenger.conf file and the rewrite Apache mod

        % sudo a2enconf passenger.conf
        % sudo a2enmod rewrite
        % sudo service apache2 restart

* Create and enable an Apache2 virtual host

  Copy the scholarspace.conf and scholarspace-ssl.conf files from the /opt/scholarspace/apache2_conf folder to /etc/apache2/sites-available/scholarspace.conf

  Enable modssl

        % sudo a2enmod ssl

  Generate certificates and place them in paths referenced in scholarspace-ssl.conf (modify the paths in scholarspace-ssl.conf if needed).  Cert file names should also match.
  
        % sudo a2dissite 000-default.conf
        % sudo a2ensite scholarspace.conf
        % sudo a2ensite scholarspace-ssl.conf
        
* Install mod_xsendfile (on the GW Scholarspace application server, if deploying on separate servers)

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

### (Optional) Add content-admin users <a id="prod-add-content-admin"></a>

* Ask each of the content-admin users to log in to the application at least once.  Right now they will have read-only rights.

* Log in as an admin user, and navigate to /roles

* Select the content-admin role, and add each of the users to whom you wish to grant content-admin rights.  These users should now be able
to upload items and edit the items that they have uploaded (plus items transferred or proxied to them).

* Note that removing users from roles through the /roles interface is currently broken, and must be accomplished through the rails console.

### (Optional) Add Google Analytics

* Enable Google Analytics in config/initializers/sufia.rb by editing the following lines:

         # Enable displaying usage statistics in the UI
         # Defaults to FALSE
         # Requires a Google Analytics id and OAuth2 keyfile.  See README for more info
         config.analytics = true
        
         # Specify a Google Analytics tracking ID to gather usage statistics
         config.google_analytics_id = 'UA-99999999-1'

         # Specify a date you wish to start collecting Google Analytic statistics for.
         config.analytic_start_date = DateTime.new(2015,11,10)

* Copy the analytics.yml.template file in config

        % cp config/analytics.yml.template config/analytics.yml

* Populate the analyitcs.yml file with your Google Analyitcs credentials.  See: https://github.com/projecthydra/sufia#analytics-and-usage-statistics for setup details.  Note that sufia seems to expect the .p12 file version of the private key, rather than the json version.

* Set up a cron job to import GA stats nightly

  Test the script to make sure that it can run successfully.  Make sure the script has execute permissions.  Your analytics.yml file must also be set up correctly in order for the script to succeed.

        % cd /opt/scholarspace/script

        % sudo chmod +x import_stats.sh

        % ./import_stats.sh production

  If it runs successfully, proceed with adding the cron job:

        % crontab -e

  Add a line similar to the following:

        0 5 * * * /opt/scholarspace/script/import_stats.sh production
        
### (Optional) Add SSL to Fedora and Solr Connections
These instructions are for redirecting port 8080 traffic on Tomcat to port 8443 and running SSL using the Apache Portable Runtime (APR).

* Install Tomcat dependencies
       
        % sudo apt-get install libapr1 libapr1-dev libtcnative-1

*  Add the `tomcat7` user to the `ssl-cert` group in `/etc/group`

        % sudo vi /etc/group

*  Generate your SSL certificates and key using the instructions provided here: https://github.com/gwu-libraries/ssl_howto

*  Copy the server_ssl.xml example from this repo to /etc/tomcat7/server.xml (note that you will need to overwrite `server.xml` (no ssl in the file name) with the contents of `server_ssl.xml` (ssl in the file name) from the repo.

        % sudo cp server_ssl.xml /etc/tomcat7/server.xml
        
*  Edit /etc/tomcat/server.xml and replace the dummy values for the following lines with your certificates and keys:
	```
        SSLCertificateFile="/etc/ssl/certs/yourservername.cer"
        SSLCertificateChainFile="/etc/ssl/certs/yourservername.cer"
        SSLCertificateKeyFile="/etc/ssl/private/yourservername.pem"
	```
*  Create a symbolic link to libtcnative1.so to address a Ubuntu/Tomcat bug
        
        % sudo ln -sv /usr/lib/x86_64-linux-gnu/libtcnative-1.so /usr/lib/

*  Replace the web.xml files for Solr and Fedora with the web_ssl.xml files from the repo:

	```
	% cp tomcat_conf/fcrepo/web_ssl.xml /var/lib/tomcat7/webapps/fcrepo/WEB-INF/web.xml
	% cp tomcat_conf/solr/web_ssl.xml /var/lib/tomcat7/webapps/solr/WEB-INF/web.xml
	```

*  Restart Tomcat and test access over HTTPS

        % sudo service tomcat7 restart
