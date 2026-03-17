import { createApp } from 'vue/dist/vue.esm-bundler.js';
import MyModuleArchive from '../../vue/my_module/archive.vue';
import { mountWithTurbolinks } from './helpers/turbolinks.js';

const app = createApp();
app.component('MyModuleArchive', MyModuleArchive);
app.config.globalProperties.i18n = window.I18n;

window.myModuleArchive = mountWithTurbolinks(app, '#myModuleArchive', () => {
  delete window.myModuleArchive;
});
