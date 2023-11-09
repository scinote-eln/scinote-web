/* global notTurbolinksPreview */
import { createApp } from 'vue/dist/vue.esm-bundler.js';
import ExportStockConsumptionModal from '../../vue/repository_row/export_stock_consumption_modal.vue';
import { mountWithTurbolinks } from './helpers/turbolinks.js';

window.initExportStockConsumptionModal = () => {
  if (window.exportStockConsumptionModalComponent) return;

  if (notTurbolinksPreview()) {
    const app = createApp({});
    app.component('ExportStockConsumptionModal', ExportStockConsumptionModal);
    app.config.globalProperties.i18n = window.I18n;
    mountWithTurbolinks(app, '#exportStockConsumtionModal');
  }
};
