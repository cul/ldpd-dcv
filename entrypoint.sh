#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f ./tmp/pids/server.pid

echo "Configuring files ..."
bundle exec rake dcv:ci:config_files

echo "Running database migrations ..."
bundle exec rails db:migrate

echo "Seeding database ..."
bundle exec rake db:seed

echo "Seeding site data from solr ..."
bundle exec rake dcv:sites:seed_from_solr

# Execute the container's main process (CMD in Dockerfile)
exec "$@"

