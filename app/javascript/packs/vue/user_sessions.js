import { createApp } from 'vue/dist/vue.esm-bundler.js';
import UserSessions from '../../vue/user_sessions/container.vue';
import { mountWithTurbolinks } from './helpers/turbolinks.js';

const app = createApp({});
app.component('UserSessions', UserSessions);
app.config.globalProperties.i18n = window.I18n;
mountWithTurbolinks(app, '#userSessions');
