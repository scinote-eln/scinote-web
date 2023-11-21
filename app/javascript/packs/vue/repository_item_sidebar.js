/* global notTurbolinksPreview */

import { createApp } from 'vue/dist/vue.esm-bundler.js';
import RepositoryItemSidebar from '../../vue/repository_item_sidebar/RepositoryItemSidebar.vue';
import { mountWithTurbolinks } from './helpers/turbolinks.js';


function initRepositoryItemSidebar() {
  const app = createApp({});
  app.component('RepositoryItemSidebar', RepositoryItemSidebar);
  app.config.globalProperties.i18n = window.I18n;
  mountWithTurbolinks(app, '#repositoryItemSidebar');
}

initRepositoryItemSidebar();
