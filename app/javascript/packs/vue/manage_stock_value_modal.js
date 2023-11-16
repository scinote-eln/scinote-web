import PerfectScrollbar from 'vue3-perfect-scrollbar';
import { createApp } from 'vue/dist/vue.esm-bundler.js';
import ManageStockValueModal from '../../vue/repository_row/manage_stock_value_modal.vue';
import { mountWithTurbolinks } from './helpers/turbolinks.js';

const app = createApp({});
app.component('ManageStockValueModal', ManageStockValueModal);
app.use(PerfectScrollbar);
app.config.globalProperties.i18n = window.I18n;
mountWithTurbolinks(app, '#manageStockValueModal');
