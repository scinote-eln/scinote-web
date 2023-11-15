import PerfectScrollbar from 'vue3-perfect-scrollbar';
import { createApp } from 'vue/dist/vue.esm-bundler.js';
import 'vue3-perfect-scrollbar/dist/vue3-perfect-scrollbar.css';
import TopMenuContainer from '../../../vue/navigation/top_menu.vue';

function addNavigationTopMenuContainer() {
  const app = createApp({});
  app.component('TopMenuContainer', TopMenuContainer);
  app.use(PerfectScrollbar);
  app.config.globalProperties.i18n = window.I18n;
  app.mount('#sciNavigationTopMenuContainer');
}

if (document.readyState !== 'loading') {
  addNavigationTopMenuContainer();
} else {
  window.addEventListener('DOMContentLoaded', () => {
    addNavigationTopMenuContainer();
  });
}
