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
   OR
   nohup solr_wrapper -d solr/config/ --collection_name hydra-development > output.log 2>&1 &
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
