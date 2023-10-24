import TurbolinksAdapter from 'vue-turbolinks';
import { createApp } from 'vue/dist/vue.esm-bundler.js';
import OpenVectorEditor from '../../vue/ove/OpenVectorEditor.vue';

const app = createApp({});
app.component('OpenVectorEditor', OpenVectorEditor);
app.use(TurbolinksAdapter);
app.config.globalProperties.i18n = window.I18n;
app.mount('#open-vector-editor');
