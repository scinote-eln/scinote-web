import { createApp } from 'vue/dist/vue.esm-bundler.js';
import OpenVectorEditor from '../../vue/ove/OpenVectorEditor.vue';
import { handleTurbolinks } from './helpers/turbolinks.js';

const app = createApp({});
app.component('OpenVectorEditor', OpenVectorEditor);
app.config.globalProperties.i18n = window.I18n;
app.mount('#open-vector-editor');
handleTurbolinks(app);
