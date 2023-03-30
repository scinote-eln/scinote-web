const path = require('path');
const webpack = require('webpack');
const { VueLoaderPlugin } = require('vue-loader');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const RemoveEmptyScriptsPlugin = require('webpack-remove-empty-scripts');
const NodePolyfillPlugin = require('node-polyfill-webpack-plugin');
const mode = process.env.NODE_ENV === 'development' ? 'development' : 'production';

module.exports = {
  mode,
  optimization: {
    moduleIds: 'deterministic'
  },
  entry: {
    application_pack: './app/javascript/packs/application.js',
    emoji_button: './app/javascript/packs/emoji_button.js',
    fonts: './app/javascript/packs/fonts.js',
    fontawesome: './app/javascript/packs/fontawesome.scss',
    prism: './app/javascript/packs/prism.js',
    tiny_mce: './app/javascript/packs/tiny_mce.js',
    tiny_mce_styles: './app/javascript/packs/tiny_mce_styles.scss',
    tui_image_editor: './app/javascript/packs/tui_image_editor.js',
    tui_image_editor_styles: './app/javascript/packs/tui_image_editor_styles.scss',
    croppie: './app/javascript/packs/custom/croppie.js',
    croppie_styles: './app/javascript/packs/custom/croppie_styles.scss',
    inputmask: './app/javascript/packs/custom/inputmask.js',
    pdfjs: './app/javascript/packs/pdfjs/pdf_js.js',
    pdf_js_styles: './app/javascript/packs/pdfjs/pdf_js_styles.scss',
    pdf_js: './app/javascript/packs/pdfjs/pdf_js.js',
    pdf_js_worker: './app/javascript/packs/pdfjs/pdf_js_worker.js',
    vue_bmt_filter: './app/javascript/packs/vue/bmt_filter.js',
    vue_label_template: './app/javascript/packs/vue/label_template.js',
    vue_protocol: './app/javascript/packs/vue/protocol.js',
    vue_repository_filter: './app/javascript/packs/vue/repository_filter.js',
    vue_repository_print_modal: './app/javascript/packs/vue/repository_print_modal.js',
    vue_navigation_top_menu: './app/javascript/packs/vue/navigation/top_menu.js'
  },
  output: {
    filename: '[name].js',
    sourceMapFilename: '[file].map',
    path: path.resolve(__dirname, '..', '..', 'app/assets/builds')
  },
  module: {
    rules: [
      {
        test: /\.vue$/,
        use: 'vue-loader'
      },
      {
        test: /\.(js)$/,
        exclude: /node_modules/,
        use: ['babel-loader']
      },
      {
        test: /\.(?:sa|sc|c)ss$/i,
        use: [MiniCssExtractPlugin.loader, 'css-loader', 'sass-loader']
      },
      {
        test: /\.(png|jpe?g|gif|svg)$/i,
        use: 'file-loader'
      }
    ]
  },
  resolve: {
    // Add additional file types
    extensions: ['.js', '.jsx', '.scss', '.css', '.vue']
  },
  plugins: [
    new webpack.optimize.LimitChunkCountPlugin({
      maxChunks: 1
    }),
    new VueLoaderPlugin(),
    new RemoveEmptyScriptsPlugin(),
    new MiniCssExtractPlugin(),
    new NodePolyfillPlugin()
  ]
};
