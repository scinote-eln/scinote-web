/* global notTurbolinksPreview */

import { createApp } from 'vue/dist/vue.esm-bundler.js';
import PerfectScrollbar from 'vue3-perfect-scrollbar';
import { vOnClickOutside } from '@vueuse/components';
import { mountWithTurbolinks } from './helpers/turbolinks.js';
import ItemRelationshipsModal from '../../vue/item_relationships/ItemRelationshipsModal.vue';

const app = createApp({});
app.component('ItemRelationshipsModal', ItemRelationshipsModal);
app.use(ItemRelationshipsModal);
app.use(PerfectScrollbar);
app.directive('click-outside', vOnClickOutside);
app.config.globalProperties.i18n = window.I18n;
mountWithTurbolinks(app, '#itemRelationshipsModalWrapper');
