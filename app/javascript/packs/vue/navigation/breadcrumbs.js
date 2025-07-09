
import { PerfectScrollbar } from 'vue3-perfect-scrollbar';
import { createApp } from 'vue/dist/vue.esm-bundler.js';
import 'vue3-perfect-scrollbar/style.css';
import Breadcrumbs from '../../../vue/navigation/breadcrumbs/breadcrumbs.vue';
import { mountWithTurbolinks } from '../helpers/turbolinks.js';


const app = createApp({});
app.component('Breadcrumbs', Breadcrumbs);
app.component('PerfectScrollbar', PerfectScrollbar);
app.config.globalProperties.i18n = window.I18n;
window.breadcrumbsComponent = mountWithTurbolinks(app, '#breadcrumbs');
