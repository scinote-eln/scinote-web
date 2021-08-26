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
        saved_filters: [],
        filters: []
      };
    },
    components: {
      'filter-container': FilterContainer
    },
    methods: {
      getFilters() {
        return this.filters.map(f => f.data)
      }
    }
  });
  $('#bmtFilterContainer').on('click', (e) => e.stopPropagation());

  $("#saveBmtFilterForm" )
    .off()
    .on('ajax:before', function() {
     $('#bmt_filter_filters').val(bmtFilterContainer.getFilters());
    })
    .on('ajax:success', function(e, result) {
      bmtFilterContainer.saved_filters.push(result.data);
      $('#modalSaveBmtFilter').modal('hide');
    });

  $.get($('#bmtFilterContainer').data('url-saved-filters'), function(result) {
    bmtFilterContainer.saved_filters = result.data;
  })
};

$('.repository-show').on('click', '.open-save-bmt-modal', () => {
  $('#modalSaveBmtFilter').modal('show');
})

