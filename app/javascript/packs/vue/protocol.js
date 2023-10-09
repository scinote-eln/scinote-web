/* global HelperModule */

import TurbolinksAdapter from 'vue-turbolinks';
import Vue from 'vue/dist/vue.esm';
import ProtocolContainer from '../../vue/protocol/container.vue';
import PerfectScrollbar from 'vue2-perfect-scrollbar';
import outsideClick from './directives/outside_click';


Vue.use(PerfectScrollbar);
Vue.use(TurbolinksAdapter);
Vue.directive('click-outside', outsideClick);
Vue.prototype.i18n = window.I18n;
Vue.prototype.inlineEditing = window.inlineEditing;
Vue.prototype.ActiveStoragePreviews = window.ActiveStoragePreviews;

window.initProtocolComponent = () => {
  Vue.prototype.dateFormat = $('#protocolContainer').data('date-format');

  $('.protocols-show').on('click', '#protocol-versions-modal .delete-draft', (e) => {
    const url = e.currentTarget.dataset.url;
    const modal = $('#deleteDraftModal');
    $('#protocol-versions-modal').modal('hide');
    modal.modal('show');
    modal.find('form').attr('action', url);
  });

  $('#deleteDraftModal form').on('ajax:error', function(_ev, data) {
    HelperModule.flashAlertMsg(data.responseJSON.message, 'danger');
  });

  new Vue({
    el: '#protocolContainer',
    components: {
      'protocol-container': ProtocolContainer
    },
    data() {
      return {
        protocolUrl: $('#protocolContainer').data('protocol-url')
      };
    }
  });
};

initProtocolComponent();
