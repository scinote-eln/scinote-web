import { createApp } from 'vue/dist/vue.esm-bundler.js';
import ScinoteEditDownload from '../../vue/shared/scinote_edit_download.vue';
import { mountWithTurbolinks } from './helpers/turbolinks.js';

const app = createApp({});
app.component('ScinoteEditDownload', ScinoteEditDownload);
app.config.globalProperties.i18n = window.I18n;
mountWithTurbolinks(app, '#scinoteEditDownload');
