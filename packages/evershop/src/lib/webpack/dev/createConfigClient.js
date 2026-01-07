import path from 'path';
import ReactRefreshWebpackPlugin from '@pmmmwh/react-refresh-webpack-plugin';
import webpack from 'webpack';
import { getEnabledExtensions } from '../../../bin/extension/index.js';
import { CONSTANTS } from '../../helpers.js';
import { createBaseConfig } from '../createBaseConfig.js';
import { GraphqlPlugin } from '../plugins/GraphqlPlugin.js';
import { InjectTailwindSources } from '../plugins/InjectTailwindSources.js';
import { ThemeWatcherPlugin } from '../plugins/ThemeWatcherPlugin.js';
import { getTailwindSources } from '../util/getTailwindSources.js';

export function createConfigClient() {
  const extensions = getEnabledExtensions();
  const tailwindSources = getTailwindSources();
  const config = createBaseConfig(false);
  config.name = 'bundle-client';

  const loaders = config.module.rules;
  loaders.unshift({
    test: /common[\\/]react[\\/]client[\\/]Index\.js$/i,
    use: [
      {
        loader: path.resolve(CONSTANTS.LIBPATH, 'webpack/loaders/AreaLoader.js')
      }
    ]
  });

  loaders.push({
    test: /\.css$/i,
    use: [
      {
        loader: 'style-loader'
      },
      {
        loader: 'css-loader',
        options: {
          url: false
        }
      },
      {
        loader: 'postcss-loader',
        options: {
          postcssOptions: {
            plugins: [
              InjectTailwindSources(tailwindSources),
              '@tailwindcss/postcss',
              'autoprefixer'
            ]
          }
        }
      }
    ]
  });

  loaders.push({
    test: /\.scss$/i,
    use: [
      {
        loader: 'style-loader'
      },
      {
        loader: 'css-loader',
        options: {
          url: false
        }
      },
      {
        loader: 'postcss-loader',
        options: {
          postcssOptions: {
            plugins: [
              InjectTailwindSources(tailwindSources),
              '@tailwindcss/postcss',
              'autoprefixer'
            ]
          }
        }
      },
      {
        loader: 'sass-loader',
        options: {
          implementation: 'sass',
          api: 'modern'
        }
      }
    ]
  });

  const { plugins } = config;
  plugins.push(new GraphqlPlugin());
  plugins.push(new webpack.ProgressPlugin());
  plugins.push(new webpack.HotModuleReplacementPlugin());
  plugins.push(
    new ReactRefreshWebpackPlugin({
      overlay: false
    })
  );
  plugins.push(new ThemeWatcherPlugin());

  config.entry = () => {
    const entry = [
      path.resolve(
        CONSTANTS.MODULESPATH,
        '../components/common/react/client/Index.js'
      ),
      `webpack-hot-middleware/client?path=/eHot&reload=true&overlay=true`
    ];
    return entry;
  };
  config.watchOptions = {
    aggregateTimeout: 300,
    ignored: new RegExp('(^|/)[a-z][^/]*.js$'),
    poll: 1000
  };

  // Enable source maps
  config.devtool = 'eval-cheap-module-source-map';

  // Configure snapshot management for better caching
  // Exclude @evershop/evershop core and extensions in node_modules from managed paths
  // This ensures webpack watches for changes in these paths
  const nodeModuleExtensions = extensions
    .filter((ext) => ext.path && ext.path.includes('node_modules'))
    .map((ext) => {
      // Extract package name from path (e.g., @vendor/package or package-name)
      const match = ext.path.match(
        /node_modules[\\/](@[^/\\]+[\\/][^/\\]+|[^/\\]+)/
      );
      return match ? match[1].replace(/\\/g, '[\\\\/]') : null;
    })
    .filter(Boolean)
    .join('|');

  const managedPathsPattern = nodeModuleExtensions
    ? `^(.+?[\\\\/]node_modules[\\\\/](?!(@evershop[\\\\/]evershop|${nodeModuleExtensions}))(@.+?[\\\\/])?.+?)[\\\\/]`
    : `^(.+?[\\\\/]node_modules[\\\\/](?!(@evershop[\\\\/]evershop))(@.+?[\\\\/])?.+?)[\\\\/]`;

  config.snapshot = {
    managedPaths: [new RegExp(managedPathsPattern)]
  };

  return config;
}
