== README

What steps are necessary to get the
application up and running?

* Ruby version: 2.6.4 (see all .ruby-version & travis matrix)

* System dependencies

* Configuration for Development
 * config files: rake dcv:ci:config_files; then edit as appropriate for proxied data:
  * blacklight.yml and solr.yml if you are using staging data, etc.
  * fedora.yml if you need to index and are using a local solr
  * update cdn_urls in dcv.yml if you are not running a local image server
 * seed site data:
  * from Solr index: rake dcv:sites:seed_from_solr
  * from an export directory for one site:  rake dcv:sites:import directory=DIRECTORY_NAME
 * administer local users: rake dcv:users:set uid=UNI email=EMAIL [is_admin=true]
  * the developer strategy will automatically log in based on the uni and email values (uni is used as the uid)
  * rake task will create or update a user, and set properties from arguments appropriately


* Database creation

* Database initialization

* How to run the test suite
 * With Homebrew:
  * brew cask install chromedriver
  * on macOS Catalina (10.15) and later, you'll need to update security settings to allow chromedriver to run because the first-time run will tell you that "the developer cannot be verified." See: https://stackoverflow.com/a/60362134
 * bundle exec rake dcv:ci

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
