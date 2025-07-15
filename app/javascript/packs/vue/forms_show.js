import { createApp } from 'vue/dist/vue.esm-bundler.js';
import { PerfectScrollbar } from 'vue3-perfect-scrollbar';
import FormShow from '../../vue/forms/show.vue';
import { mountWithTurbolinks } from './helpers/turbolinks.js';

const app = createApp();
app.component('FormShow', FormShow);
app.config.globalProperties.i18n = window.I18n;
app.component('PerfectScrollbar', PerfectScrollbar);
mountWithTurbolinks(app, '#formShow');
