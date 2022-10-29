const { webpackConfig, merge } = require('shakapacker')
// See the shakacode/shakapacker README and docs directory for advice on customizing your webpackConfig.

const customConfig = {
	resolve: {
		extensions: ['.js', '.jsx', '.css', '.scss'],
		fallback: {
			stream: require.resolve("stream-browserify"),
			buffer: false,
		}
	},
	module: {
		rules: [
			{
				test: require.resolve("jquery"),
				loader: "expose-loader",
				options: {
					exposes: ["$", "jQuery"],
				},
			},
   			{
				test: /\.s[ac]ss$/,
				use: [
					{
						loader: 'sass-loader',
						options: {
							sourceMap: true,
						}
					},
				],
			},
		],
	}
}

module.exports = merge(webpackConfig, customConfig);
