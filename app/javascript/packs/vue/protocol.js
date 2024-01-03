/* global HelperModule */

import PerfectScrollbar from 'vue3-perfect-scrollbar';
import { createApp } from 'vue/dist/vue.esm-bundler.js';
import ProtocolContainer from '../../vue/protocol/container.vue';
import { mountWithTurbolinks } from './helpers/turbolinks.js';

window.initProtocolComponent = () => {
  const app = createApp({
    data() {
      return {
        protocolUrl: $('#protocolContainer').data('protocol-url'),
      };
    },
  });
  app.component('ProtocolContainer', ProtocolContainer);
  app.use(PerfectScrollbar);
  app.config.globalProperties.i18n = window.I18n;
  app.config.globalProperties.inlineEditing = window.inlineEditing;
  app.config.globalProperties.ActiveStoragePreviews = window.ActiveStoragePreviews;
  app.config.globalProperties.dateFormat = $('#protocolContainer').data('date-format');
  mountWithTurbolinks(app, '#protocolContainer');

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
};

initProtocolComponent();
