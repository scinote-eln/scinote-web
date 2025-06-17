import { createApp } from 'vue/dist/vue.esm-bundler.js';
import PerfectScrollbar from 'vue3-perfect-scrollbar';
import UserGroupsTable from '../../vue/user_groups/index.vue';
import { mountWithTurbolinks } from './helpers/turbolinks.js';

const app = createApp();
app.component('UserGroupsTable', UserGroupsTable);
app.config.globalProperties.i18n = window.I18n;
app.use(PerfectScrollbar);
mountWithTurbolinks(app, '#userGroupsTable');
