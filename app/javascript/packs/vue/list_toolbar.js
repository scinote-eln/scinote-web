/* global notTurbolinksPreview */

import TurbolinksAdapter from 'vue-turbolinks';
import Vue from 'vue/dist/vue.esm';
import PerfectScrollbar from 'vue2-perfect-scrollbar';
import ListToolbar from '../../vue/components/list_toolbar.vue';

Vue.use(TurbolinksAdapter);
Vue.use(PerfectScrollbar);
Vue.prototype.i18n = window.I18n;

window.initListToolbar = () => {
  if (window.listToolbarComponent) return;
  if (notTurbolinksPreview()) {
    new Vue({
      el: '#listToolbar',
      components: {
        ListToolbar
      }
    });
  }
}
