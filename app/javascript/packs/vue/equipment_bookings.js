import { createApp } from 'vue/dist/vue.esm-bundler.js';
import EquipmentBookings from '../../vue/equipment_bookings/index.vue';
import { mountWithTurbolinks } from './helpers/turbolinks.js';

const app = createApp();
app.component('EquipmentBookings', EquipmentBookings);
app.config.globalProperties.i18n = window.I18n;
mountWithTurbolinks(app, '#equipmentBookings');
