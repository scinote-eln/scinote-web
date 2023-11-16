import { createApp } from 'vue/dist/vue.esm-bundler.js';
import RepositorySearchContainer from '../../vue/repository_search/container.vue';
import { mountWithTurbolinks } from './helpers/turbolinks.js';

Vue.use(TurbolinksAdapter);
Vue.prototype.i18n = window.I18n;

window.initRepositorySearch = () => {
  const app = createApp({});
  app.component('RepositorySearchContainer', RepositorySearchContainer);
  app.config.globalProperties.i18n = window.I18n;
  mountWithTurbolinks(app, '#inventorySearchComponent');
}
