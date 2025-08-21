import { createApp } from 'vue/dist/vue.esm-bundler.js';
import MyModuleShow from '../../vue/my_module/show.vue';
import { mountWithTurbolinks } from './helpers/turbolinks.js';

const app = createApp();
app.component('MyModuleShow', MyModuleShow);
app.config.globalProperties.i18n = window.I18n;

window.myModuleShow = mountWithTurbolinks(app, '#myModuleShow', () => {
  delete window.myModuleShow;
});
