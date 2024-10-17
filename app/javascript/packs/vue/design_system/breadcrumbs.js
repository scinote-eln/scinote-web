import { createApp } from 'vue/dist/vue.esm-bundler.js';
import Breadcrumbs from '../../../vue/shared/breadcrumbs.vue';
import { mountWithTurbolinks } from '../helpers/turbolinks.js';

const app = createApp({
  computed: {
    breadcrumbs() {
      return [
        { name: 'Home', url: '/' },
        { name: 'Very very very long name ', url: '' },
        { name: 'Data', url: '' },
        { name: 'Very very very very very very very very very very long name ', url: '' },
        { name: 'Very very very very very very very  long name ', url: '' },
        { name: 'Very very very very very long name ', url: '' },
        { name: 'Very very very very long name ', url: '' }
      ];
    }
  }
});
app.component('Breadcrumbs', Breadcrumbs);
app.config.globalProperties.i18n = window.I18n;
mountWithTurbolinks(app, '#breadcrumbs');
