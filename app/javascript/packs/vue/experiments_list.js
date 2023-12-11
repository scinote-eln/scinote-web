import { createApp } from 'vue/dist/vue.esm-bundler.js';
import PerfectScrollbar from 'vue3-perfect-scrollbar';
import ExperimentsList from '../../vue/experiments/list.vue';
import { mountWithTurbolinks } from './helpers/turbolinks.js';

const app = createApp();
app.component('ExperimentsList', ExperimentsList);
app.config.globalProperties.i18n = window.I18n;
app.use(PerfectScrollbar);
mountWithTurbolinks(app, '#ExperimentsList');
