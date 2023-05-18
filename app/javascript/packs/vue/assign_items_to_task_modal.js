import TurbolinksAdapter from 'vue-turbolinks';
import Vue from 'vue/dist/vue.esm';
import AssignItemsToTaskModalContainer from '../../vue/assign_items_to_tasks_modal/container.vue';

Vue.use(TurbolinksAdapter);
Vue.prototype.i18n = window.I18n;

function initAssignItemsToTaskModalComponent() {
  const container = $('.assign-items-to-task-modal-container');
  if (container.length) {
    window.AssignItemsToTaskModalComponentContainer = new Vue({
      el: '.assign-items-to-task-modal-container',
      name: 'AssignItemsToTaskModalComponent',
      components: {
        'assign-items-to-task-modal-container': AssignItemsToTaskModalContainer
      },
      data() {
        return {
          visibility: false,
          urls: {
            assign: container.data('assign-url'),
            projects: container.data('projects-url'),
            experiments: container.data('experiments-url'),
            tasks: container.data('tasks-url')
          }
        };
      },
      methods: {
        showModal() {
          this.visibility = true;
        },
        closeModal() {
          this.visibility = false;
        }
      }
    });
  }
}

initAssignItemsToTaskModalComponent();
