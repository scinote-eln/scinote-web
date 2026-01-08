import { createApp } from 'vue/dist/vue.esm-bundler.js';
import ProtocolRepositoryRows from '../../vue/protocol/repository_rows.vue';
import { mountWithTurbolinks } from './helpers/turbolinks.js';

window.initProtocolRepositoryRowsComponent = () => {
  const app = createApp({});
  app.component('ProtocolRepositoryRows', ProtocolRepositoryRows);
  app.config.globalProperties.i18n = window.I18n;
  mountWithTurbolinks(app, '#protocolRepositoryRows');
};

initProtocolRepositoryRowsComponent();
