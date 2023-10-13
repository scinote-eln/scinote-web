import TurbolinksAdapter from 'vue-turbolinks';
import Vue from 'vue/dist/vue.esm';
import UserPreferences from '../../vue/user_preferences/container.vue';
import PerfectScrollbar from 'vue2-perfect-scrollbar';

Vue.use(TurbolinksAdapter);
Vue.use(PerfectScrollbar);
Vue.prototype.i18n = window.I18n;

new Vue({
  el: '#user_preferences',
  components: { UserPreferences }
});
