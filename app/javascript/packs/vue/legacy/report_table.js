import { createApp } from 'vue/dist/vue.esm-bundler.js';
import NativeTableRenderer from '../../../vue/reports/native_table_renderer.vue';
import { mountWithTurbolinks } from '../helpers/turbolinks.js';

window.initReportNativeTableRenderer = (id) => {
  const app = createApp({});
  app.component('NativeTableRenderer', NativeTableRenderer);
  mountWithTurbolinks(app, id);
};

const tables = document.querySelectorAll('.report-native-table');
tables.forEach((table) => {
  window.initReportNativeTableRenderer(`#${table.id}`);
});
