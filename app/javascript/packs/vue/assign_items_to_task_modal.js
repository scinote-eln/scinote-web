
import PerfectScrollbar from 'vue3-perfect-scrollbar';
import { createApp } from 'vue/dist/vue.esm-bundler.js';
import 'vue3-perfect-scrollbar/dist/vue3-perfect-scrollbar.css';
import AssignItemsToTaskModalContainer from '../../vue/assign_items_to_tasks_modal/container.vue';
import { mountWithTurbolinks } from './helpers/turbolinks.js';

function initAssignItemsToTaskModalComponent() {
  const container = $('.assign-items-to-task-modal-container');
  if (container.length) {
    const app = createApp({
      data() {
        return {
          visibility: false,
          rowsToAssign: [],
          urls: {
            assign: container.data('assign-url'),
            projects: container.data('projects-url'),
            experiments: container.data('experiments-url'),
            tasks: container.data('tasks-url')
          }
        };
      },
      methods: {
        showModal(repositoryRows) {
          this.rowsToAssign = repositoryRows;
          this.visibility = true;
        },
        closeModal() {
          this.visibility = false;
        }
      }
    });
    app.component('AssignItemsToTaskModalContainer', AssignItemsToTaskModalContainer);
    app.use(PerfectScrollbar);
    app.config.globalProperties.i18n = window.I18n;
    window.AssignItemsToTaskModalComponentContainer = mountWithTurbolinks(app, '.assign-items-to-task-modal-container');
  }
}

initAssignItemsToTaskModalComponent();
