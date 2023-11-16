/* global notTurbolinksPreview */

import { createApp } from 'vue/dist/vue.esm-bundler.js';
import TurbolinksAdapter from 'vue-turbolinks';
import Vue from 'vue/dist/vue.esm';
import 'vue2-perfect-scrollbar/dist/vue2-perfect-scrollbar.css';
import PerfectScrollbar from 'vue2-perfect-scrollbar';
import RepositoryItemSidebar from '../../vue/repository_item_sidebar/RepositoryItemSidebar.vue';
import outsideClick from './directives/outside_click';
import { mountWithTurbolinks } from './helpers/turbolinks.js';

Vue.use(TurbolinksAdapter);
Vue.directive('click-outside', outsideClick);
Vue.use(PerfectScrollbar);
Vue.prototype.i18n = window.I18n;

function initRepositoryItemSidebar() {
  const app = createApp({});
  app.component('RepositoryItemSidebar', RepositoryItemSidebar);
  app.config.globalProperties.i18n = window.I18n;
  mountWithTurbolinks(app, '#repositoryItemSidebar');
}

initRepositoryItemSidebar();
