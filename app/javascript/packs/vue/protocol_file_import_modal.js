import { createApp } from 'vue/dist/vue.esm-bundler.js';
import ProtocolFileImportModal from '../../vue/protocol_import/file_import_modal.vue';
import { mountWithTurbolinks } from './helpers/turbolinks.js';

window.initProtocolFileImportModalComponent = () => {
  const app = createApp({});
  app.component('ProtocolFileImportModal', ProtocolFileImportModal);
  app.config.globalProperties.i18n = window.I18n;
  mountWithTurbolinks(app, '#protocolFileImportModal');
};

initProtocolFileImportModalComponent();
