
import Vue from 'vue/dist/vue.esm';
import TopMenuContainer from '../../../vue/navigation/top_menu.vue';

Vue.prototype.i18n = window.I18n;

window.addEventListener('DOMContentLoaded', () => {
  new Vue({
    el: '#sciNavigationTopMenuContainer',
    components: {
      'top-menu-container': TopMenuContainer
    }
  });
});
