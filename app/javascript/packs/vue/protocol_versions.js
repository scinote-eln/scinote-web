import { createApp } from 'vue/dist/vue.esm-bundler.js';
import ProtocolVersions from '../../vue/protocol/versions_block.vue';
import { mountWithTurbolinks } from './helpers/turbolinks.js';

window.initProtocolVersionsBlockComponent = () => {
  const app = createApp({});
  app.component('ProtocolVersions', ProtocolVersions);
  app.config.globalProperties.i18n = window.I18n;
  mountWithTurbolinks(app, '#protocolVersionsBlock');
};

initProtocolVersionsBlockComponent();
