/* global notTurbolinksPreview */

import { createApp } from 'vue/dist/vue.esm-bundler.js';
import PerfectScrollbar from 'vue3-perfect-scrollbar';
import NewTaskModal from '../../../vue/dashboard/new_task_modal.vue';
import { mountWithTurbolinks } from '../helpers/turbolinks.js';

window.initNewTaskModalComponent = () => {
  if (window.newTaskModalComponent) return;

  if (notTurbolinksPreview()) {
    const app = createApp({});
    app.component('CreateNewTaskModal', NewTaskModal);
    app.use(PerfectScrollbar);
    app.config.globalProperties.i18n = window.I18n;
    mountWithTurbolinks(app, '#newTaskModal', () => {
      window.newTaskModalComponent = null;
    });
  }
};
window.initNewTaskModalComponent();
