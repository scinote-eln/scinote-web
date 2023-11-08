import { createApp } from 'vue/dist/vue.esm-bundler.js';
import RepositorySearchContainer from '../../vue/repository_search/container.vue';
import outsideClick from './directives/outside_click';
import { handleTurbolinks } from './helpers/turbolinks.js';

window.initRepositorySearch = () => {
  const app = createApp({});
  app.component('RepositorySearchContainer', RepositorySearchContainer);
  app.directive('click-outside', outsideClick);
  app.config.globalProperties.i18n = window.I18n;
  app.mount('#inventorySearchComponent');
  handleTurbolinks(app);

  window.RepositorySearchComponent = app;
}
