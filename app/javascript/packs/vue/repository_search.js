import TurbolinksAdapter from 'vue-turbolinks';
import { createApp } from 'vue/dist/vue.esm-bundler.js';
import RepositorySearchContainer from '../../vue/repository_search/container.vue';
import outsideClick from './directives/outside_click';

window.initRepositorySearch = () => {
  const app = createApp({});
  app.component('RepositorySearchContainer', RepositorySearchContainer);
  app.use(TurbolinksAdapter);
  app.directive('click-outside', outsideClick);
  app.config.globalProperties.i18n = window.I18n;
  app.mount('#inventorySearchComponent');

  window.RepositorySearchComponent = app;
}
