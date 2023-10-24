/* global notTurbolinksPreview */

import TurbolinksAdapter from 'vue-turbolinks';
import { createApp } from 'vue/dist/vue.esm-bundler.js';
import ActionToolbar from '../../vue/components/action_toolbar.vue';

window.initActionToolbar = () => {
  if (window.actionToolbarComponent) return;
  if (notTurbolinksPreview()) {
    const app = createApp({});
    app.component('ActionToolbar', ActionToolbar);
    app.use(TurbolinksAdapter);
    app.config.globalProperties.i18n = window.I18n;
    app.mount('#actionToolbar');
  }
}
