import TurbolinksAdapter from 'vue-turbolinks';
import { createApp } from 'vue/dist/vue.esm-bundler.js';
import PrintModalContainer from '../../vue/repository_print_modal/container.vue';

function initPrintModalComponent() {
  const container = $('.print-label-modal-container');
  if (container.length) {
    const app = createApp({
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
    app.component('PrintModalContainer', PrintModalContainer);
    app.use(TurbolinksAdapter);
    app.config.globalProperties.i18n = window.I18n;
    app.mount('.print-label-modal-container');
    window.PrintModalComponent = app;
  }
}

initPrintModalComponent();
