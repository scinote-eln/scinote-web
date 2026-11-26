import { createApp } from 'vue/dist/vue.esm-bundler.js';
import PillTabGroup from '../../../vue/shared/pill_tab_group.vue';
import { mountWithTurbolinks } from '../helpers/turbolinks.js';

const app = createApp({
  data() {
    return {
      selected: {
        md: 'tasks',
        sm: 'tasks',
        mdIcons: 'tasks',
        smIcons: 'tasks',
        mdDisabled: 'projects',
        smDisabled: 'projects'
      }
    };
  }
});
app.component('PillTabGroup', PillTabGroup);
mountWithTurbolinks(app, '#pill-tab-group-demo');
