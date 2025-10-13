import { createApp } from 'vue/dist/vue.esm-bundler.js';
import DateTimePicker from '../../../vue/shared/date_time_picker.vue';
import { mountWithTurbolinks } from '../helpers/turbolinks.js';

const app = createApp({
  computed: {
    todayDate() {
      return new Date();
    }
  }
});
app.component('DateTimePicker', DateTimePicker);
app.config.globalProperties.i18n = window.I18n;
mountWithTurbolinks(app, '#datepickers');
