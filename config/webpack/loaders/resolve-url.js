const path = require('path');
const {
  createJoinFunction,
  createJoinImplementation,
  asGenerator,
  defaultJoinGenerator,
} = require('resolve-url-loader');

const sourceFolders = [
  'app/assets/images',
  'app/javascript/assets',
  'app/javascript/images',
  'node_modules/leaflet/dist',
].map(function(sourceFolder){ return path.resolve(sourceFolder)});

// call default generator then append any additional paths
const myGenerator = asGenerator(
  (item, ...rest) => {
    const val = Array.from(defaultJoinGenerator(item, ...rest));
    if (item.isAbsolute) {
      val.push(null)
    } else {
      sourceFolders.forEach(function(sourceFolder){ val.push([sourceFolder, item.uri]) });
    }
    return val;
  }
);

const myJoinFn = createJoinFunction(
  'myJoinFn',
  createJoinImplementation(myGenerator),
);

module.exports = {
  module: {
    rules: [
      {
        test: /\.css$/,
        use: [
          'style-loader',
          'css-loader',
        ],
        exclude: [/node_modules/]
      },
      {
        test: /\.scss$/,
        use: [
          {
            loader: 'css-loader',
            options: {
              import: false
            }
          },
          {
            loader: 'resolve-url-loader',
            options: {
              join: myJoinFn
            }
          },
          {
            loader: 'sass-loader',
            options: {
              sourceMap: true, // <-- !!IMPORTANT!!
            }
          }
        ]
      }
    ]
  }
}