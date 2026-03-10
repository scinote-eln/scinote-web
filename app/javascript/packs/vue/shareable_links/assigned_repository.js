import { createApp } from 'vue/dist/vue.esm-bundler.js';
import { PerfectScrollbar } from 'vue3-perfect-scrollbar';
import AssignedItems from '../../../vue/shareable_links/assigned_items.vue';
import { mountWithTurbolinks } from '../helpers/turbolinks.js';

const app = createApp();
app.component('AssignedItems', AssignedItems);
app.config.globalProperties.i18n = window.I18n;
app.component('PerfectScrollbar', PerfectScrollbar);

window.shareableLinksAssignedItems = mountWithTurbolinks(app, '#assignedItems', () => {
  delete window.shareableLinksAssignedItems;
});
