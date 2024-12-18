// See the shakacode/shakapacker README and docs directory for advice on customizing your webpackConfig.
const { generateWebpackConfig, merge } = require('shakapacker')

const erb = require('./loaders/erb');
const expose = require('./loaders/expose');
const resolveUrl = require('./loaders/resolve-url');
const workers = require('./loaders/workers');
const webpack = require('webpack');
const ReactRefreshWebpackPlugin = require('@pmmmwh/react-refresh-webpack-plugin');
const isDevelopment = process.env.NODE_ENV === 'development';

const customConfig = {
  resolve: {
    fallback: { "url": require.resolve("url/") }
  },
  plugins: [
    new webpack.ProvidePlugin({
      Popper: ['popper.js', 'default'],
      Rails: ['@rails/ujs'],
      Hls: 'hls.js',
      Cookies: 'js-cookie',
      Alert: 'exports-loader?Alert!bootstrap/js/dist/alert',
      Button: 'exports-loader?Button!bootstrap/js/dist/button',
      Carousel: 'exports-loader?Carousel!bootstrap/js/dist/carousel',
      Collapse: 'exports-loader?Collapse!bootstrap/js/dist/collapse',
      Dropdown: 'exports-loader?Dropdown!bootstrap/js/dist/dropdown',
      Modal: 'exports-loader?Modal!bootstrap/js/dist/modal',
      Popover: 'exports-loader?Popover!bootstrap/js/dist/popover',
      Scrollspy: 'exports-loader?Scrollspy!bootstrap/js/dist/scrollspy',
      Tab: 'exports-loader?Tab!bootstrap/js/dist/tab',
      Tooltip: "exports-loader?Tooltip!bootstrap/js/dist/tooltip",
      Util: 'exports-loader?Util!bootstrap/js/dist/util'
    }),
    isDevelopment ? new ReactRefreshWebpackPlugin() : null
  ].filter(Boolean)
}

const webpackConfig = generateWebpackConfig()

module.exports = merge(webpackConfig, merge(workers, merge(resolveUrl, merge(expose, merge(erb, customConfig)))));