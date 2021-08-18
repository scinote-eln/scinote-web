import TurbolinksAdapter from 'vue-turbolinks';
import Vue from 'vue/dist/vue.esm';
import FilterContainer from '../../vue/bmt_filter/container.vue';

Vue.use(TurbolinksAdapter);


window.initBMTFilter = () => {
  const app = new Vue({
    el: '#bmtFilterContainer',
    components: {
      'filter-container': FilterContainer
    }
  });

  $('#bmtFilterContainer').on('click', (e) => {
    e.preventDefault();
    e.stopPropagation();
  });
};
