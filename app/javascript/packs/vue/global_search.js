import { createApp } from 'vue/dist/vue.esm-bundler.js';
import { PerfectScrollbar } from 'vue3-perfect-scrollbar';
import GlobalSearch from '../../vue/global_search/container.vue';
import { mountWithTurbolinks } from './helpers/turbolinks.js';

const app = createApp();
app.component('global_search', GlobalSearch);
app.config.globalProperties.i18n = window.I18n;
app.component('PerfectScrollbar', PerfectScrollbar);
mountWithTurbolinks(app, '#GlobalSearch');
