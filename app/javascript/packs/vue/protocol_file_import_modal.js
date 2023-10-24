import TurbolinksAdapter from 'vue-turbolinks';
import { createApp } from 'vue/dist/vue.esm-bundler.js';
import ProtocolFileImportModal from '../../vue/protocol_import/file_import_modal.vue';

window.initProtocolFileImportModalComponent = () => {
  const app = createApp({});
  app.component('ProtocolFileImportModal', ProtocolFileImportModal);
  app.use(TurbolinksAdapter);
  app.config.globalProperties.i18n = window.I18n;
  app.mount('#protocolFileImportModal');
};

initProtocolFileImportModalComponent();
