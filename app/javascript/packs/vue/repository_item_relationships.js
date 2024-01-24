/* global notTurbolinksPreview */

import { createApp } from 'vue/dist/vue.esm-bundler.js';
import PerfectScrollbar from 'vue3-perfect-scrollbar';
import { vOnClickOutside } from '@vueuse/components';
import { mountWithTurbolinks } from './helpers/turbolinks.js';
import RepositoryItemRelationshipsModal from '../../vue/item_relationships/RepositoryItemRelationshipsModal.vue';

const app = createApp({});
app.component('RepositoryItemRelationshipsModal', RepositoryItemRelationshipsModal);
app.use(RepositoryItemRelationshipsModal);
app.use(PerfectScrollbar);
app.directive('click-outside', vOnClickOutside);
app.config.globalProperties.i18n = window.I18n;
mountWithTurbolinks(app, '#repositoryItemRelationshipsModalWrapper');
