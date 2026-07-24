import { createApp } from 'vue/dist/vue.esm-bundler.js';
import { PerfectScrollbar } from 'vue3-perfect-scrollbar';
import TagsTable from '../../vue/tags/index.vue';
import { mountWithTurbolinks } from './helpers/turbolinks.js';
import Vue3TouchEvents from "vue3-touch-events";

const app = createApp();
app.component('TagsTable', TagsTable);
app.config.globalProperties.i18n = window.I18n;
app.use(PerfectScrollbar);
app.use(Vue3TouchEvents);
mountWithTurbolinks(app, '#tagsTable');
