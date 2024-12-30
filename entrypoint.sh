#!/bin/bash
set -e

cleanup() {
    echo "Running cleanup tasks..."
    echo "Restoring config to local defaults ..."
    rm ./config/solr.yml
    rm ./config/blacklight.yml
    bundle exec rake dcv:ci:config_files
    echo "Sending signal to shut down solr tunnel"
    echo "SHUTDOWN TUNNEL" > ./tmp/tunnel_shutdown;
}

# run cleanup on shutdown
trap cleanup SIGINT SIGTERM

# Remove a potentially pre-existing server.pid for Rails.
rm -f ./tmp/pids/server.pid

echo "Running database migrations ..."
bundle exec rails db:migrate

echo "Seeding database ..."
bundle exec rake db:seed

echo "Seeding site data from solr ..."
bundle exec rake dcv:sites:seed_from_solr

# Execute the container's main process (CMD in Dockerfile)
# exec "$@"

#Trap SIGTERM
# trap 'true' SIGTERM
trap cleanup SIGTERM

#Execute command
"${@}" &

wait $!

# cleanup
