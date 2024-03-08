/* global notTurbolinksPreview */

import { createApp } from 'vue/dist/vue.esm-bundler.js';
import PerfectScrollbar from 'vue3-perfect-scrollbar';
import CreateNewTaskModal from '../../../vue/dashboard/create_new_task_modal.vue';
import { mountWithTurbolinks } from '../helpers/turbolinks.js';

window.initCreateNewTaskModalComponent = () => {
  if (window.createNewTaskModalComponent) return;

  if (notTurbolinksPreview()) {
    const app = createApp({});
    app.component('CreateNewTaskModal', CreateNewTaskModal);
    app.use(PerfectScrollbar);
    app.config.globalProperties.i18n = window.I18n;
    mountWithTurbolinks(app, '#createNewTaskModal', () => {
      window.createNewTaskModalComponent = null;
    });
  }
};
window.initCreateNewTaskModalComponent();
