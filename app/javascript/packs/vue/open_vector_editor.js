import TurbolinksAdapter from 'vue-turbolinks';
import Vue from 'vue/dist/vue.esm';
import OpenVectorEditor from '../../vue/ove/OpenVectorEditor.vue';

Vue.use(TurbolinksAdapter);
Vue.prototype.i18n = window.I18n;

new Vue({
  el: '#open-vector-editor',
  components: { OpenVectorEditor }
});
