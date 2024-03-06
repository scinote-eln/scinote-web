import { createApp } from 'vue/dist/vue.esm-bundler.js';
import PerfectScrollbar from 'vue3-perfect-scrollbar';
import AccessModal from '../../../vue/shared/access_modal/modal.vue';
import { mountWithTurbolinks } from '../helpers/turbolinks.js';

window.initAccessModalComponent = (id) => {
  const app = createApp({
    data() {
      return {
        accessModalOpen: false,
        params: {}
      };
    },
    mounted() {
      $(this.$refs.accessModal).data('accessModal', this);
    },
    methods: {
      open() {
        this.accessModalOpen = true;
      },
      close() {
        this.accessModalOpen = false;
      }
    }
  });
  app.component('access-modal', AccessModal);
  app.use(PerfectScrollbar);
  app.config.globalProperties.i18n = window.I18n;
  mountWithTurbolinks(app, id);
};

const accessModalContainers = document.querySelectorAll('.vue-access-modal:not(.initialized)');
accessModalContainers.forEach((container) => {
  $(container).addClass('initialized');
  window.initAccessModalComponent(`#${container.id}`);
});
