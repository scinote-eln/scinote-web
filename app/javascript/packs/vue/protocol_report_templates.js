import { createApp } from 'vue/dist/vue.esm-bundler.js';
import ProtocolReportTemplates from '../../vue/protocol/protocol_report_templates.vue';
import { mountWithTurbolinks } from './helpers/turbolinks.js';

window.initProtocolReportTemplatesComponent = () => {
  const app = createApp({});
  app.component('ProtocolReportTemplates', ProtocolReportTemplates);
  app.config.globalProperties.i18n = window.I18n;
  mountWithTurbolinks(app, '#protocolReportTemplates');
};

initProtocolReportTemplatesComponent();
