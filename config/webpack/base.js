const { globalMutableWebpackConfig, merge } = require('shakapacker');

const erb = require('./loaders/erb');
const expose = require('./loaders/expose');
const resolveUrl = require('./loaders/resolve-url');
const workers = require('./loaders/workers');
const webpack = require('webpack');

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
		})
	]
}

const mergeableConfigs = [
	erb,
	expose,
	resolveUrl,
	workers,
	globalMutableWebpackConfig
]

module.exports = mergeableConfigs.reduce((accumulator, currentValue) => merge(accumulator, currentValue), customConfig);
