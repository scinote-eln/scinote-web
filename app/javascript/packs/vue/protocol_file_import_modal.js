import TurbolinksAdapter from 'vue-turbolinks';
import Vue from 'vue/dist/vue.esm';
import ProtocolFileImportModal from '../../vue/protocol_import/file_import_modal.vue';


Vue.use(TurbolinksAdapter);
Vue.prototype.i18n = window.I18n;

window.initProtocolFileImportModalComponent = () => {
  new Vue({
    el: '#protocolFileImportModal',
    components: {
      'protocol-file-import-modal': ProtocolFileImportModal
    }
  });
};

initProtocolFileImportModalComponent();
