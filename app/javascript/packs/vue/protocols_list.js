import { createApp } from 'vue/dist/vue.esm-bundler.js';
import PerfectScrollbar from 'vue3-perfect-scrollbar';
import ProtocolsTable from '../../vue/protocols/table.vue';
import { mountWithTurbolinks } from './helpers/turbolinks.js';

const app = createApp();
app.component('ProtocolsTable', ProtocolsTable);
app.config.globalProperties.i18n = window.I18n;
app.use(PerfectScrollbar);
window.protocolsTable = mountWithTurbolinks(app, '#ProtocolsTable', () => {
  delete window.protocolsTable;
});
