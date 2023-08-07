import Vue from 'vue/dist/vue.esm';
import ShareLinkContainer from '../../vue/shareable_links/container.vue';
import PerfectScrollbar from 'vue2-perfect-scrollbar';
import 'vue2-perfect-scrollbar/dist/vue2-perfect-scrollbar.css';


Vue.use(PerfectScrollbar);

Vue.prototype.i18n = window.I18n;

function initShareTaskContainer() {
  new Vue({
    el: '.share-task-container',
    components: {
      'share-task-container': ShareLinkContainer
    }
  });
}

initShareTaskContainer();
