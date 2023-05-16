/* global I18n */

import TurbolinksAdapter from 'vue-turbolinks';
import Vue from 'vue/dist/vue.esm';
import ActionToolbar from '../../vue/components/action_toolbar.vue';

Vue.use(TurbolinksAdapter);

window.initActionToolbar = () => {
  new Vue({
    el: '#actionToolbar',
    components: {
      ActionToolbar
    }
  });
}
