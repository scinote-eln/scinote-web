import TurbolinksAdapter from 'vue-turbolinks';
import Vue from 'vue/dist/vue.esm';
import Breadcrumbs from '../../../vue/navigation/breadcrumbs/breadcrumbs.vue';
import PerfectScrollbar from 'vue2-perfect-scrollbar';
import 'vue2-perfect-scrollbar/dist/vue2-perfect-scrollbar.css';

Vue.use(TurbolinksAdapter);
Vue.use(PerfectScrollbar);
Vue.prototype.i18n = window.I18n;

window.breadcrumbsComponent = new Vue({
  el: '#breadcrumbs',
  name: 'BreadcrumbsContainer',
  components: {
    breadcrumbs: Breadcrumbs
  }
});
