/* global notTurbolinksPreview */

import { createApp } from 'vue/dist/vue.esm-bundler.js';
import ActionToolbar from '../../vue/components/action_toolbar.vue';
import { handleTurbolinks } from './helpers/turbolinks.js';

window.initActionToolbar = () => {

  if (notTurbolinksPreview()) {
    const app = createApp({});
    app.component('ActionToolbar', ActionToolbar);
    app.config.globalProperties.i18n = window.I18n;
    app.mount('#actionToolbar');
    handleTurbolinks(app);
  }
}
