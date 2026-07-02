import { createApp } from 'vue/dist/vue.esm-bundler.js';
import ProtocolAnalyticalReports from '../../vue/protocol/analytical_reports.vue';
import { mountWithTurbolinks } from './helpers/turbolinks.js';

window.initProtocolAnalyticalReportsComponent = () => {
  const app = createApp({});
  app.component('ProtocolAnalyticalReports', ProtocolAnalyticalReports);
  app.config.globalProperties.i18n = window.I18n;
  mountWithTurbolinks(app, '#protocolAnalyticalReports');
};

initProtocolAnalyticalReportsComponent();
