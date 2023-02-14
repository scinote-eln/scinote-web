const { environment } = require('@rails/webpacker')
const { VueLoaderPlugin } = require('vue-loader')
const vue = require('./loaders/vue')
const { execSync } = require('child_process');
const { basename, resolve } = require('path');
const { readdirSync } = require('fs');

environment.loaders.delete('nodeModules')
environment.plugins.prepend('VueLoaderPlugin', new VueLoaderPlugin())
environment.loaders.prepend('vue', vue)

// Engine pack loading based on https://github.com/rails/webpacker/issues/348#issuecomment-635480949
// Get paths to all engines' folders
console.log('Including packs from addons...');

let enginePaths = [];

try {
  enginePaths = execSync('ls -d $PWD/addons/*').toString().split('\n').filter((p) => !!p);
} catch {
  console.log('Unable to find any addons.')
}

enginePaths.forEach((path) => {
  const packsFolderPath = `${path}/app/javascript/packs`;

  let entryFiles;
  try {
    entryFiles = readdirSync(packsFolderPath);
    console.log(`Found packs in ${path}`);
  } catch {
    console.log(`No packs in ${path}`);
    return;
  }

  entryFiles.forEach((file) => {
    // File name without .js
    const name = basename(file, '.js');
    const entryPath = `${packsFolderPath}/${file}`;

    environment.entry.set(name, entryPath);
  });

  // Otherwise babel won't transpile the file
  environment.loaders.get('babel').include.push(`${path}/app/javascript`);
});

module.exports = environment;
