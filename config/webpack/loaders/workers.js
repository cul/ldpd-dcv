module.exports = {
  test: /\.worker\.js$/,
  enforce: 'pre',
  exclude: /node_modules/,
  use: [{
    loader: 'worker-loader',
  }]
}
