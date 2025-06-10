import { createApp } from 'vue/dist/vue.esm-bundler.js';
import ExperimentDescriptionModal from '../../vue/my_modules/modals/experiment_description_modal.vue';
import { mountWithTurbolinks } from './helpers/turbolinks.js';

const app = createApp();
app.component('ExperimentDescriptionModal', ExperimentDescriptionModal);
app.config.globalProperties.i18n = window.I18n;
window.experimentDescriptionModal = mountWithTurbolinks(app, '#experimentDescriptionModal');
