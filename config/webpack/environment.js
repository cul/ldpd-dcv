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
    })
)

environment.loaders.get('sass').use.splice(-1, 0, resolveUrl);
environment.loaders.prepend('erb', erb)
environment.loaders.forEach(function(loader) {
    console.log(loader.key);
    console.log(JSON.stringify(loader.value, null, 2));
});
module.exports = environment
