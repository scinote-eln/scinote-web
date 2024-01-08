import { createApp } from 'vue/dist/vue.esm-bundler.js';
import PerfectScrollbar from 'vue3-perfect-scrollbar';
import RepositoriesTable from '../../vue/repositories/table.vue';
import { mountWithTurbolinks } from './helpers/turbolinks.js';

const app = createApp();
app.component('RepositoriesTable', RepositoriesTable);
app.config.globalProperties.i18n = window.I18n;
app.use(PerfectScrollbar);
mountWithTurbolinks(app, '#repositoriesTable');
