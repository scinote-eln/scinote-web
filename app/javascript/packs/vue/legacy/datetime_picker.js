import { createApp } from 'vue/dist/vue.esm-bundler.js';
import DateTimePicker from '../../../vue/shared/date_time_picker.vue';
import { mountWithTurbolinks } from '../helpers/turbolinks.js';
/*
<div  id="date-time-picker" class="vue-date-time-picker">
  <input ref="input" type="hidden" v-model="date" id="legacy-id" data-default="" />
  <date-time-picker ref="vueDateTime" @change="updateDate" :mode="date"></date-time-picker>
</div>
*/

window.initDateTimePickerComponent = (id) => {
  const elementWithIdPresent = document.querySelector(id);
  if (!elementWithIdPresent) {
    console.warn("datetime_picker.js -> window.initDateTimePickerComponent: couldn't find element with id: ", id);
    return;
  }

  const app = createApp({
    data() {
      return {
        date: null,
        onChange: null
      };
    },
    mounted() {
      if (this.$refs.input.dataset.default) {
        const defaultDate = new Date(this.$refs.input.dataset.default.replace(/([^!\s])-/g, '$1/')); // Safari fix
        this.date = this.formatDate(defaultDate);
        this.$refs.vueDateTime.manualUpdate = true;
        this.$refs.vueDateTime.datetime = defaultDate;
      } else if (this.date) {
        this.$refs.vueDateTime.manualUpdate = true;
        this.$refs.vueDateTime.datetime = new Date(this.date);
      }

      $(this.$refs.input).data('dateTimePicker', this);
      $(this.$el.parentElement).parent().trigger('dp:ready');
    },
    methods: {
      formatDate(date) {
        if (!(date instanceof Date)) return null;

        if (this.$refs.input.dataset.simpleFormat) {
          const y = date.getFullYear();
          const m = date.getMonth() + 1;
          const d = date.getDate();
          const hours = date.getHours();
          const mins = date.getMinutes();
          return `${y}/${m}/${d} ${hours}:${mins}`;
        }
        return date.toISOString();
      },
      updateDate(date) {
        this.date = this.formatDate(date);
        this.$nextTick(() => {
          if (this.onChange) this.onChange(date);
        });

      },
      setDate(date) {
        this.date = this.formatDate(date);
        this.$refs.vueDateTime.manualUpdate = true;
        this.$refs.vueDateTime.datetime = date;
        this.$nextTick(() => {
          if (this.onChange) this.onChange(date);
        });
      },
      clearDate() {
        this.date = null;
        this.$refs.vueDateTime.datetime = null;
        this.$nextTick(() => {
          if (this.onChange) this.onChange(null);
        });
      }
    }
  });
  app.component('DateTimePicker', DateTimePicker);
  app.config.globalProperties.i18n = window.I18n;
  mountWithTurbolinks(app, id);
};

document.addEventListener('turbolinks:load', () => {
  const dateTimePickers = document.querySelectorAll('.vue-date-time-picker');
  dateTimePickers.forEach((dateTimePicker) => {
    window.initDateTimePickerComponent(`#${dateTimePicker.id}`);
  });
})
