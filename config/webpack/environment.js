const { environment } = require('@rails/webpacker')
const erb = require('./loaders/erb')
const resolveUrl = require('./loaders/resolve-url');
const webpack = require('webpack')

environment.plugins.prepend(
    'Provide',
    new webpack.ProvidePlugin({
        $: 'jquery',
        jQuery: 'jquery',
        jquery: 'jquery',
        'window.jQuery': 'jquery',
        Popper: ['popper.js', 'default'],
        Rails: ['@rails/ujs'],
        Hls: 'hls.js',
        Cookies: 'js-cookie'
    })
)

environment.loaders.get('sass').use.splice(-1, 0, resolveUrl);
environment.loaders.prepend('erb', erb)

module.exports = environment
