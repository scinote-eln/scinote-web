import { createApp } from 'vue/dist/vue.esm-bundler.js';
import InputTitleField from '../../../vue/shared/input_title_field.vue';
import { mountWithTurbolinks } from '../helpers/turbolinks.js';

const app = createApp({
  data() {
    return {
      testValue: 'Lorem ipsum dolor sit amet consectetur adipiscing elit',
    }
  },
  computed: {
    error() {
      return this.testValue.length > 10;
    },
    errorMessage() {
      return 'is too long (maximum is 10 characters)';
    }
  }
});
app.component('InputTitleField', InputTitleField);
app.config.globalProperties.i18n = window.I18n;
mountWithTurbolinks(app, '#titleInputs');
