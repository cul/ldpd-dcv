module.exports = {
  module: {
    rules: [
      {
        test: /\.worker\.js$/,
        enforce: 'pre',
        exclude: /node_modules/,
        loader: 'worker-loader'
      }
    ]
  }
}
