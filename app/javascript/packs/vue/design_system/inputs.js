import { createApp } from 'vue/dist/vue.esm-bundler.js';
import InputField from '../../../vue/shared/input_field.vue';
import { mountWithTurbolinks } from '../helpers/turbolinks.js';

const app = createApp({
  data() {
    return {
      testValue: ''
    };
  },
  watch: {
    testValue(value) {
      console.log(value);
    }
  }
});
app.component('InputField', InputField);
app.config.globalProperties.i18n = window.I18n;
mountWithTurbolinks(app, '#inputs');
