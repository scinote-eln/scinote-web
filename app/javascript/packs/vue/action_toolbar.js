/* global notTurbolinksPreview */

import TurbolinksAdapter from 'vue-turbolinks';
import Vue from 'vue/dist/vue.esm';
import ActionToolbar from '../../vue/components/action_toolbar.vue';

Vue.use(TurbolinksAdapter);
Vue.prototype.i18n = window.I18n;

window.initActionToolbar = () => {
  if (window.actionToolbarComponent) return;
  if (notTurbolinksPreview()) {
    new Vue({
      el: '#actionToolbar',
      components: {
        ActionToolbar
      }
    });
  }
}
