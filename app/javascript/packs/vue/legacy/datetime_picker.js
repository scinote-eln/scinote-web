import TurbolinksAdapter from 'vue-turbolinks';
import { createApp } from 'vue/dist/vue.esm-bundler.js';
import DateTimePicker from '../../../vue/shared/date_time_picker.vue';

/*
<div  id="date-time-picker" class="vue-date-time-picker">
  <input ref="input" type="hidden" v-model="date" id="legacy-id" data-default="" />
  <date-time-picker ref="vueDateTime" @change="updateDate" :mode="date"></date-time-picker>
</div>
*/

window.initDateTimePickerComponent = (id) => {
  const app = createApp({
    data() {
      return {
        date: null,
        onChange: null
      };
    },
    mounted() {
      if (this.$refs.input.dataset.default) {
        const defaultDate = new Date(this.$refs.input.dataset.default.replace(/-/g, '/')); // Safari fix
        this.date = this.formatDate(defaultDate);
        this.$refs.vueDateTime.datetime = defaultDate;
      } else if (this.date) {
        this.$refs.vueDateTime.datetime = new Date(this.date);
      }


      $(this.$refs.input).data('dateTimePicker', this);
      $(this.$el.parentElement).parent().trigger('dp:ready');
    },
    methods: {
      formatDate(date) {
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
  app.use(TurbolinksAdapter);
  app.config.globalProperties.i18n = window.I18n;
  app.mount(id);


};

document.addEventListener('turbolinks:load', () => {
  const dateTimePickers = document.querySelectorAll('.vue-date-time-picker');
  dateTimePickers.forEach((dateTimePicker) => {
    window.initDateTimePickerComponent(`#${dateTimePicker.id}`);
  });
})