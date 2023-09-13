import TurbolinksAdapter from 'vue-turbolinks';
import Vue from 'vue/dist/vue.esm';
import Results from '../../vue/results/results.vue';
import PerfectScrollbar from 'vue2-perfect-scrollbar';
import outsideClick from './directives/outside_click';


Vue.use(PerfectScrollbar);
Vue.use(TurbolinksAdapter);
Vue.directive('click-outside', outsideClick);
Vue.prototype.i18n = window.I18n;
Vue.prototype.ActiveStoragePreviews = window.ActiveStoragePreviews;

new Vue({
  el: '#results',
  components: {
    Results
  }
});
