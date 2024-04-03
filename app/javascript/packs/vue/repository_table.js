import { createApp } from 'vue/dist/vue.esm-bundler.js';
import PerfectScrollbar from 'vue3-perfect-scrollbar';
import RepositoryTable from '../../vue/repository/table.vue';
import { mountWithTurbolinks } from './helpers/turbolinks.js';

window.mountRepositoryTable = (el = '#repositoryTable') => {
  const app = createApp();
  app.component('RepositoryTable', RepositoryTable);
  app.config.globalProperties.i18n = window.I18n;
  app.use(PerfectScrollbar);
  if (document.getElementById('repositoryTable') || el !== '#repositoryTable') {
    mountWithTurbolinks(app, el);
  }
};

window.mountRepositoryTable();
