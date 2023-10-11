/* global notTurbolinksPreview */

import TurbolinksAdapter from 'vue-turbolinks';
import Vue from 'vue/dist/vue.esm';
import ExportStockConsumptionModal from '../../vue/repository_row/export_stock_consumption_modal.vue';

Vue.use(TurbolinksAdapter);
Vue.prototype.i18n = window.I18n;

window.initExportStockConsumptionModal = () => {
  if (window.exportStockConsumptionModalComponent) return;

  if (notTurbolinksPreview()) {
    new Vue({
      el: '#exportStockConsumtionModal',
      components: {
        ExportStockConsumptionModal,
      },
    });
  }
};
