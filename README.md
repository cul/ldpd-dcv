# README

## What steps are necessary to get the
application up and running?

* Ruby version: 2.6.4 (see all .ruby-version & travis matrix)

* System dependencies
  * A Solr index, which supports search and display of records
    * configured in two places (`blacklight.yml` and `solr.yml`) under the current mix of library dependencies
  * A Fedora repository, which supports MODS XML (for indexing and downloads) and asset retrieval
    * not necessary if using an existing index
  * A IIIF/derivative service, which provides thumbnails and images
    * configured in `dcv.yml` under `cdn_urls`
  * A streaming media service (Wowza)
    * configured in `dcv.yml` under `media_streaming`
    * not necessary unless testing token generation/streaming

* Configuration for Local/Desktop Development
  * install dependencies: `bundle install`
  * set up config files: `bundle exec rake dcv:ci:config_files`; then edit as appropriate for proxied data:
    * If you are using live (prod, staging) indexes, it will require SSH tunneling and editing blacklight.yml and solr.yml
      * This is probably what you are trying to do
      * see instructions at https://wiki.library.columbia.edu/display/DLC/Developers for how to update blacklight.yml and solr.yml
    * If you are using a local Solr to test indexing, you will need to edit fedora.yml
      * It is unlikely that you are doing this
      * see instructions at https://wiki.library.columbia.edu/display/DLC/Developers
    * update cdn_urls in dcv.yml if you are not running a local image server
  * set up local database `bundle exec rake db:migrate`
    * if you are testing NYRE projects, seed data with `bundle exec rake db:seed`
  * seed site data:
    * from Solr index: `bundle exec rake dcv:sites:seed_from_solr`
    * from an export directory for one site: `bundle exec rake dcv:sites:import directory=DIRECTORY_NAME`
  * administer local users: `bundle exec rake dcv:users:set uid=UNI email=EMAIL [is_admin=true]`
    * the developer strategy will automatically log in based on the uni and email values (uni is used as the uid)
    * rake task will create or update a user, and set properties from arguments appropriately


* Database creation
  * `bundle exec rake db:migrate`

* Database initialization
  * `bundle exec rake db:seed`

## User permissions and restricted access Assets

Although Item metadata records are generally visible in DLC, some Assets are restricted and require your currently logged in user to have the correct permissions.  For how to configure user permissions, see: [https://wiki.library.columbia.edu/display/DLC/Authorization+Metadata]

## How to run the test suite
* With Homebrew:
  * brew cask install chromedriver
  * on macOS Catalina (10.15) and later, you'll need to update security settings to allow chromedriver to run because the first-time run will tell you that "the developer cannot be verified." See: https://stackoverflow.com/a/60362134
* bundle exec rake dcv:ci
  * this will download and run a local fedora and solr and set up test data

* Services (job queues, cache servers, search engines, etc.)
  * resque TBD

* Deployment instructions
  * capistrano TBD

* ...
