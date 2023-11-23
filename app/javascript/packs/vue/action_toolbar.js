/* global notTurbolinksPreview */

import { createApp } from 'vue/dist/vue.esm-bundler.js';
import ActionToolbar from '../../vue/components/action_toolbar.vue';
import { mountWithTurbolinks } from './helpers/turbolinks.js';

window.initActionToolbar = () => {
  if (window.actionToolbarComponent) return;

  if (notTurbolinksPreview()) {
    const app = createApp({});
    app.component('ActionToolbar', ActionToolbar);
    app.config.globalProperties.i18n = window.I18n;
    mountWithTurbolinks(app, '#actionToolbar', () => {
      window.actionToolbarComponent = null
    });
  }
}
