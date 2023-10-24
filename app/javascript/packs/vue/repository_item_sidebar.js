/* global notTurbolinksPreview */

import TurbolinksAdapter from 'vue-turbolinks';
import { createApp } from 'vue/dist/vue.esm-bundler.js';
import RepositoryItemSidebar from '../../vue/repository_item_sidebar/RepositoryItemSidebar.vue';


function initRepositoryItemSidebar() {
  const app = createApp({});
  app.component('RepositoryItemSidebar', RepositoryItemSidebar);
  app.use(TurbolinksAdapter);
  app.config.globalProperties.i18n = window.I18n;
  app.mount('#repositoryItemSidebar');
}

initRepositoryItemSidebar();
