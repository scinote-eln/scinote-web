import { PerfectScrollbar } from 'vue3-perfect-scrollbar';
import { createApp } from 'vue/dist/vue.esm-bundler.js';
import TeamAutomations from '../../vue/team_automations/container.vue';
import { mountWithTurbolinks } from './helpers/turbolinks.js';

const app = createApp({});
app.component('TeamAutomations', TeamAutomations);
app.component('PerfectScrollbar', PerfectScrollbar);
app.config.globalProperties.i18n = window.I18n;
mountWithTurbolinks(app, '#team_automations');
