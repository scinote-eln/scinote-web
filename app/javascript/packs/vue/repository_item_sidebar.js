/* global notTurbolinksPreview */

import PerfectScrollbar from 'vue3-perfect-scrollbar';
import { createApp } from 'vue/dist/vue.esm-bundler.js';
import { vOnClickOutside } from '@vueuse/components';
import { mountWithTurbolinks } from './helpers/turbolinks.js';
import RepositoryItemSidebar from '../../vue/repository_item_sidebar/RepositoryItemSidebar.vue';

const app = createApp({});
app.component('RepositoryItemSidebar', RepositoryItemSidebar);
app.use(RepositoryItemSidebar);
app.use(PerfectScrollbar);
app.directive('click-outside', vOnClickOutside)
app.config.globalProperties.i18n = window.I18n;
mountWithTurbolinks(app, '#repositoryItemSidebar');
