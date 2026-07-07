import { createApp } from 'vue/dist/vue.esm-bundler.js';
import { PerfectScrollbar } from 'vue3-perfect-scrollbar';
import AnalyticalReports from '../../vue/my_module/analytical_reports.vue';
import { mountWithTurbolinks } from './helpers/turbolinks.js';

window.initMyModuleAnalyticalReportsComponent = () => {
  const app = createApp({});
  app.component('AnalyticalReports', AnalyticalReports);
  app.config.globalProperties.i18n = window.I18n;
  mountWithTurbolinks(app, '#analyticalReports');
};

initMyModuleAnalyticalReportsComponent();
