import TurbolinksAdapter from 'vue-turbolinks';
import Vue from 'vue/dist/vue.esm';
import FilterContainer from '../../vue/bmt_filter/container.vue';

Vue.use(TurbolinksAdapter);
Vue.prototype.i18n = window.I18n;

window.initBMTFilter = () => {
  const app = new Vue({
    el: '#bmtFilterContainer',
    components: {
      'filter-container': FilterContainer
    }
  });

  $('#bmtFilterContainer').on('click', (e) => e.stopPropagation());
};
