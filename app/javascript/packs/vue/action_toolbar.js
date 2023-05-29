/* global notTurbolinksPreview */

import TurbolinksAdapter from 'vue-turbolinks';
import Vue from 'vue/dist/vue.esm';
import ActionToolbar from '../../vue/components/action_toolbar.vue';

Vue.use(TurbolinksAdapter);

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
