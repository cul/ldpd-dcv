#!/bin/bash
set -e

cleanup() {
    echo "Running cleanup tasks..."
    echo "Restoring config to local defaults ..."
    rm ./config/solr.yml
    rm ./config/blacklight.yml
    bundle exec rake dcv:ci:config_files
    echo "Sending signal to shut down solr tunnel"
    echo "SHUTDOWN TUNNEL" > ./tmp/shutdown_tunnel_signal;
}

# run cleanup on shutdown
trap cleanup SIGINT SIGTERM

# Remove a potentially pre-existing server.pid for Rails.
rm -f ./tmp/pids/server.pid

# shakapacker has no promptless option without overwriting, so we preserve and restore existing config
echo "Checking shakapacker installation..."
cp config/shakapacker.yml config/shakapacker.yml.dlc
cp config/webpack/webpack.config.js config/webpack/webpack.config.js.dlc
cp package.json package.json.dlc

FORCE=true bundle exec rails shakapacker:install 

mv config/shakapacker.yml.dlc config/shakapacker.yml
mv config/webpack/webpack.config.js.dlc config/webpack/webpack.config.js
mv package.json.dlc package.json

yarn add jquery --save

echo "Running database migrations ..."
bundle exec rails db:migrate

echo "Seeding database ..."
bundle exec rake db:seed

echo "Seeding site data from solr ..."
bundle exec rake dcv:sites:seed_from_solr


trap cleanup SIGTERM

echo "Starting rails and shakapacker-dev-server"
"${@}" &

#keep as main process so that SIGTERM triggers cleanup
wait $!
