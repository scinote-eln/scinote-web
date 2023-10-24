import TurbolinksAdapter from 'vue-turbolinks';
import PerfectScrollbar from 'vue3-perfect-scrollbar';
import { createApp } from 'vue/dist/vue.esm-bundler.js';
import Results from '../../vue/results/results.vue';
import outsideClick from './directives/outside_click';

const app = createApp({});
app.component('Results', Results);
app.use(TurbolinksAdapter);
app.use(PerfectScrollbar);
app.directive('click-outside', outsideClick);
app.config.globalProperties.i18n = window.I18n;
app.config.globalProperties.ActiveStoragePreviews = window.ActiveStoragePreviews;
app.mount('#results');
