import TurbolinksAdapter from 'vue-turbolinks'
import Vue from 'vue/dist/vue.esm'
import FilterContainer from '../../vue/bmt_filter/container.vue'

Vue.use(TurbolinksAdapter)

var app = null

window.initBMTFilter = function() {
  app = new Vue({
    el: '#bmtFilterContainer',
    components: {
      'filter-container': FilterContainer
    }
  })

  $('#bmtFilterContainer').on('click', function(e){
    e.preventDefault();
    e.stopPropagation();
  })
}
