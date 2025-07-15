/* global */

import { PerfectScrollbar } from 'vue3-perfect-scrollbar';
import { createApp } from 'vue/dist/vue.esm-bundler.js';
import { mountWithTurbolinks } from './helpers/turbolinks.js';
import RepositoryItemErrorSidebar from '../../vue/repository_item_sidebar/RepositoryItemErrorSidebar.vue';

const app = createApp({});
app.component('RepositoryItemErrorSidebar', RepositoryItemErrorSidebar);
app.component('PerfectScrollbar', PerfectScrollbar);
app.config.globalProperties.i18n = window.I18n;
mountWithTurbolinks(app, '#repositoryItemErrorSidebar');
