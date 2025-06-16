import { PerfectScrollbar } from 'vue3-perfect-scrollbar';
import { createApp } from 'vue/dist/vue.esm-bundler.js';
import 'vue3-perfect-scrollbar/style.css';
import ShareLinkContainer from '../../vue/shareable_links/container.vue';
import { mountWithTurbolinks } from './helpers/turbolinks.js';

const app = createApp({});
app.component('ShareTaskContainer', ShareLinkContainer);
app.component('PerfectScrollbar', PerfectScrollbar);
app.config.globalProperties.i18n = window.I18n;
mountWithTurbolinks(app, '#share-task-container');
