import TurbolinksAdapter from 'vue-turbolinks';
import Vue from 'vue/dist/vue.esm';
import PrintModalContainer from '../../vue/repository_print_modal/container.vue';

Vue.use(TurbolinksAdapter);
Vue.prototype.i18n = window.I18n;

function initPrintModalComponent() {
  const container = $('.print-label-modal-container');
  if (container.length) {
    window.PrintModalComponent = new Vue({
      el: '.print-label-modal-container',
      name: 'PrintModalComponent',
      components: {
        'print-modal-container': PrintModalContainer
      },
      data() {
        return {
          showModal: false,
          row_ids: [],
          urls: {
            print: container.data('print-url'),
            zebraProgress: container.data('zebra-progress-url'),
            printers: container.data('printers-url'),
            labelTemplates: container.data('label-templates-url'),
            rows: container.data('rows-url'),
            fluicsInfo: container.data('fluics-info-url'),
            printValidation: container.data('print-validation-url'),
            labelPreview: container.data('label-preview-url')
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
}

initPrintModalComponent();
