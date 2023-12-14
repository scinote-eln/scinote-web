import PerfectScrollbar from 'vue3-perfect-scrollbar';
import { createApp } from 'vue/dist/vue.esm-bundler.js';
import UserPreferences from '../../vue/user_preferences/container.vue';
import { mountWithTurbolinks } from './helpers/turbolinks.js';

const app = createApp({});
app.component('UserPreferences', UserPreferences);
app.use(PerfectScrollbar);
app.config.globalProperties.i18n = window.I18n;
mountWithTurbolinks(app, '#user_preferences');
