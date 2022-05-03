/* global I18n */

import TurbolinksAdapter from 'vue-turbolinks';
import Vue from 'vue/dist/vue.esm';
import ProtocolContainer from '../../vue/protocol/container.vue';

Vue.use(TurbolinksAdapter);
Vue.prototype.i18n = window.I18n;

window.initProtocolComponent = () => {
  Vue.prototype.dateFormat = $('#protocolContainer').data('date-format');

  new Vue({
    el: '#protocolContainer',
    components: {
      'protocol-container': ProtocolContainer
    },
    data() {
      return {
        protocolUrl: $('#protocolContainer').data('protocol-url'),
        stepsUrl: $('#protocolContainer').data('steps-url'),
        addStepUrl: $('#protocolContainer').data('add-step-url'),
        editable: $('#protocolContainer').data('editable')
      };
    }
  });
};

initProtocolComponent();
