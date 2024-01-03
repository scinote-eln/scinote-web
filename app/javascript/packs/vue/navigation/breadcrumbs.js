
import PerfectScrollbar from 'vue3-perfect-scrollbar';
import { createApp } from 'vue/dist/vue.esm-bundler.js';
import 'vue3-perfect-scrollbar/dist/vue3-perfect-scrollbar.css';
import Breadcrumbs from '../../../vue/navigation/breadcrumbs/breadcrumbs.vue';
import { mountWithTurbolinks } from '../helpers/turbolinks.js';


const app = createApp({});
app.component('Breadcrumbs', Breadcrumbs);
app.use(PerfectScrollbar);
app.config.globalProperties.i18n = window.I18n;
window.breadcrumbsComponent = mountWithTurbolinks(app, '#breadcrumbs');
