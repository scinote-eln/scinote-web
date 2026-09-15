import { createApp } from 'vue/dist/vue.esm-bundler.js';
import { PerfectScrollbar } from 'vue3-perfect-scrollbar';
import MyModuleReports from '../../vue/my_module/reports.vue';
import { mountWithTurbolinks } from './helpers/turbolinks.js';

window.initMyModuleReportsComponent = () => {
  const app = createApp({});
  app.component('MyModuleReports', MyModuleReports);
  app.config.globalProperties.ActiveStoragePreviews = window.ActiveStoragePreviews;
  app.config.globalProperties.i18n = window.I18n;
  mountWithTurbolinks(app, '#myModuleReports');
};

initMyModuleReportsComponent();
