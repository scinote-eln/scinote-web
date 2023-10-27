import TurbolinksAdapter from 'vue-turbolinks';
import Vue from 'vue/dist/vue.esm';
import PerfectScrollbar from 'vue2-perfect-scrollbar';
import 'vue2-perfect-scrollbar/dist/vue2-perfect-scrollbar.css';
import ManageStockValueModal from '../../vue/repository_row/manage_stock_value_modal.vue';

Vue.use(PerfectScrollbar);
Vue.use(TurbolinksAdapter);
Vue.prototype.i18n = window.I18n;

window.initManageStockValueModalComponent = () => {
  if (window.manageStockModalComponent) return;

  if (notTurbolinksPreview()) {
    new Vue({
      el: '#manageStockValueModal',
      components: {
        'manage-stock-value-modal': ManageStockValueModal,
      },
    });
  }
};

initManageStockValueModalComponent();
