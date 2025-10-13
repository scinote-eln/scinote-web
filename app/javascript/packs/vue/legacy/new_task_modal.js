import { createApp } from 'vue/dist/vue.esm-bundler.js';
import { PerfectScrollbar } from 'vue3-perfect-scrollbar';
import NewTaskModal from '../../../vue/my_modules/modals/new.vue'
import { mountWithTurbolinks } from '../helpers/turbolinks.js';

window.initNewTaskModalComponent = (id) => {
  const app = createApp({
    data() {
      return {
        newTaskModalOpen: false,
      };
    },
    mounted() {
      $(this.$refs.newTaskModal).data('newTaskModal', this);
    },
    methods: {
      open() {
        this.newTaskModalOpen = true;
      },
      close() {
        this.newTaskModalOpen = false;
      },
      reloadLocation() {
        window.location.reload();
      }
    }
  });
  app.component('new-task-modal', NewTaskModal);
  app.component('PerfectScrollbar', PerfectScrollbar);
  app.config.globalProperties.i18n = window.I18n;
  mountWithTurbolinks(app, id);
};

const newTaskModalContainers = document.querySelectorAll('.vue-new-task-modal:not(.initialized)');
newTaskModalContainers.forEach((container) => {
  $(container).addClass('initialized');
  window.initNewTaskModalComponent(`#${container.id}`);
});
