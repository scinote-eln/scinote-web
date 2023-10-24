/* global notTurbolinksPreview */

import TurbolinksAdapter from 'vue-turbolinks';
import { createApp } from 'vue/dist/vue.esm-bundler.js';
import ExportStockConsumptionModal from '../../vue/repository_row/export_stock_consumption_modal.vue';

window.initExportStockConsumptionModal = () => {
  if (window.exportStockConsumptionModalComponent) return;

  if (notTurbolinksPreview()) {
    const app = createApp({});
    app.component('ExportStockConsumptionModal', ExportStockConsumptionModal);
    app.use(TurbolinksAdapter);
    app.config.globalProperties.i18n = window.I18n;
    app.mount('#exportStockConsumtionModal');
  }
};
