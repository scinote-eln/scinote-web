import { createApp } from 'vue/dist/vue.esm-bundler.js';
import OpenLocallyMenu from '../../vue/shared/content/attachments/open_locally_menu.vue';
import { mountWithTurbolinks } from './helpers/turbolinks.js';

const app = createApp({});
app.component('OpenLocallyMenu', OpenLocallyMenu);
app.config.globalProperties.i18n = window.I18n;
mountWithTurbolinks(app, '#openLocallyMenu');
