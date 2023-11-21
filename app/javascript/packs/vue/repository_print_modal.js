import { createApp } from 'vue/dist/vue.esm-bundler.js';
import PrintModalContainer from '../../vue/repository_print_modal/container.vue';
import { mountWithTurbolinks } from './helpers/turbolinks.js';

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
        },
        openModal() {
          this.showModal = true;
        }
      }
    });
    app.component('PrintModalContainer', PrintModalContainer);
    app.config.globalProperties.i18n = window.I18n;
    window.PrintModalComponent = mountWithTurbolinks(app, '.print-label-modal-container');
  }
}

initPrintModalComponent();
