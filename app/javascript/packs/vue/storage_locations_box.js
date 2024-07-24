import { createApp } from 'vue/dist/vue.esm-bundler.js';
import PerfectScrollbar from 'vue3-perfect-scrollbar';
import StorageLocationsBox from '../../vue/storage_locations/box.vue';
import { mountWithTurbolinks } from './helpers/turbolinks.js';

const app = createApp();
app.component('StorageLocationsBox', StorageLocationsBox);
app.config.globalProperties.i18n = window.I18n;
app.use(PerfectScrollbar);
mountWithTurbolinks(app, '#storageLocationsBox');
