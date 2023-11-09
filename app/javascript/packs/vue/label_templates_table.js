import { createApp } from 'vue/dist/vue.esm-bundler.js';
import PerfectScrollbar from 'vue3-perfect-scrollbar';
import LabelTemplatesTable from '../../vue/label_template/table.vue';
import { handleTurbolinks } from './helpers/turbolinks.js';

const app = createApp();
app.component('LabelTemplatesTable', LabelTemplatesTable);
app.config.globalProperties.i18n = window.I18n;
app.use(PerfectScrollbar);
app.mount('#labelTemplatesTable');
handleTurbolinks(app);

