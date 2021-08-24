import TurbolinksAdapter from 'vue-turbolinks';
import Vue from 'vue/dist/vue.esm';
import FilterContainer from '../../vue/bmt_filter/container.vue';

Vue.use(TurbolinksAdapter);
Vue.prototype.i18n = window.I18n;

window.initBMTFilter = () => {
  const bmtFilterContainer = new Vue({
    el: '#bmtFilterContainer',
    data: () => {
      return {
        saved_filters: []
      };
    },
    components: {
      'filter-container': FilterContainer
    }
  });
  $('#bmtFilterContainer').on('click', (e) => e.stopPropagation());

  $( "#saveBmtFilterForm" ).off().submit(function(e) {
    let filterName = $(this).find('input#filter_name').val();
    bmtFilterContainer.saved_filters.push({
      id: bmtFilterContainer.saved_filters.length,
      filter_name: filterName,
      filters: []
    });
  });

};

$('.repository-show').on('click', '.open-save-bmt-modal', () => {
  $('#modalSaveBmtFilter').modal('show')
})

