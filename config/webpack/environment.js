const { environment } = require('@rails/webpacker');
const erb = require('./loaders/erb');
const resolveUrl = require('./loaders/resolve-url');
const workers = require('./loaders/workers');
const webpack = require('webpack');

environment.plugins.prepend(
    'Provide',
    new webpack.ProvidePlugin({
        $: 'jquery',
        jQuery: 'jquery',
        jquery: 'jquery',
        'window.jQuery': 'jquery',
        Popper: ['popper.js', 'default'],
        Rails: ['@rails/ujs'],
    })
)

environment.loaders.get('sass').use.splice(-1, 0, resolveUrl);
environment.loaders.prepend('workers', workers)
environment.loaders.prepend('erb', erb)

module.exports = environment
