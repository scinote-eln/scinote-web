
import { createApp } from 'vue/dist/vue.esm-bundler.js';
import 'vue3-perfect-scrollbar/style.css';
import EventCreateRepositoryRow from '../../vue/equipment_bookings/event_create_repository_row.vue';
import { mountWithTurbolinks } from './helpers/turbolinks.js';

function initEventCreateRepositoryRowComponent() {
  const container = $('.event-create-repository-row');
  if (container.length) {
    const app = createApp({
      data() {
        return {
          repositoryId: container.data('repository-id'),
          repositoryRowId: null,
          visibility: false,
          startHidden: true
        };
      },
      methods: {
        showModal(repositoryRowId) {
          this.repositoryRowId = repositoryRowId;
          this.visibility = true;
        },
        closeModal() {
          this.visibility = false;
        }
      }
    });
    app.component('EventCreateRepositoryRow', EventCreateRepositoryRow);
    app.config.globalProperties.i18n = window.I18n;
    window.EventCreateRepositoryRow = mountWithTurbolinks(app, '.event-create-repository-row');
  }
}

initEventCreateRepositoryRowComponent();
