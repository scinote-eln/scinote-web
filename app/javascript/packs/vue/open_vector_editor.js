import { createApp } from 'vue/dist/vue.esm-bundler.js';
import OpenVectorEditor from '../../vue/ove/OpenVectorEditor.vue';
import { mountWithTurbolinks } from './helpers/turbolinks.js';

const app = createApp({});
app.component('OpenVectorEditor', OpenVectorEditor);
app.config.globalProperties.i18n = window.I18n;
mountWithTurbolinks(app, '#open-vector-editor');
