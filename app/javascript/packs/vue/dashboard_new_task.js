import { createApp } from 'vue/dist/vue.esm-bundler.js';
import PerfectScrollbar from 'vue3-perfect-scrollbar';
import DashboardNewTask from '../../vue/dashboard/new_task.vue';
import { mountWithTurbolinks } from './helpers/turbolinks.js';

const app = createApp({
  data() {
    return {
      modalKey: 0
    };
  }
});
app.component('DashboardNewTask', DashboardNewTask);
app.config.globalProperties.i18n = window.I18n;
app.use(PerfectScrollbar);
mountWithTurbolinks(app, '#DashboardNewTask');
