
import Vue from 'vue/dist/vue.esm';
import TopMenuContainer from '../../../vue/navigation/top_menu.vue';
import PerfectScrollbar from 'vue2-perfect-scrollbar';
import 'vue2-perfect-scrollbar/dist/vue2-perfect-scrollbar.css';
import outsideClick from '../directives/outside_click';

Vue.use(PerfectScrollbar);
Vue.directive('click-outside', outsideClick);
Vue.prototype.i18n = window.I18n;

function addNavigationTopMenuContainer() {
  new Vue({
    el: '#sciNavigationTopMenuContainer',
    components: {
      'top-menu-container': TopMenuContainer
    }
  });
}

if (document.readyState !== 'loading') {
  addNavigationTopMenuContainer();
} else {
  window.addEventListener('DOMContentLoaded', () => {
    addNavigationTopMenuContainer();
  });
}
