import TurbolinksAdapter from 'vue-turbolinks';
import Vue from 'vue/dist/vue.esm';
import PrintModalContainer from '../../vue/repository_print_modal/container.vue';

Vue.use(TurbolinksAdapter);
Vue.prototype.i18n = window.I18n;

function initPrintModalComponent() {
  const container = $('.print-label-modal-container');

  window.PrintModalComponent = new Vue({
    el: '.print-label-modal-container',
    components: {
      'print-modal-container': PrintModalContainer
    },
    data() {
      return {
        showModal: false,
        row_ids: [],
        zebraEnabled: container.data('zebra-enabled'),
        urls: {
          print: container.data('print-url'),
          zebraProgress: container.data('zebra-progress-url'),
          printers: container.data('printers-url'),
          labelTemplates: container.data('label-templates-url'),
          rows: container.data('rows-url'),
          fluicsInfo: container.data('fluics-info-url')
        }
      };
    },
    methods: {
      closeModal() {
        this.showModal = false;
      }
    }
  });
}

initPrintModalComponent();
