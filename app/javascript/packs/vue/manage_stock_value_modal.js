import PerfectScrollbar from 'vue3-perfect-scrollbar';
import { createApp } from 'vue/dist/vue.esm-bundler.js';
import ManageStockValueModal from '../../vue/repository_row/manage_stock_value_modal.vue';
import { mountWithTurbolinks } from './helpers/turbolinks.js';


window.initManageStockValueModalComponent = () => {
  if (window.manageStockModalComponent) return;
  // eslint-disable-next-line no-undef
  if (notTurbolinksPreview()) {
    const app = createApp({});
    app.component('ManageStockValueModal', ManageStockValueModal);
    app.use(PerfectScrollbar);
    app.config.globalProperties.i18n = window.I18n;
    mountWithTurbolinks(app, '#manageStockValueModal', () => {
      window.manageStockModalComponent = null;
    });
  }
};
