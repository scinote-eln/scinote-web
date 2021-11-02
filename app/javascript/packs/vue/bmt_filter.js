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
        bmtApiBaseUrl: $($('#bmtFilterContainer')).data('bmt-api-base-url'),
        savedFilters: [],
        filters: []
      };
    },
    created() {
      this.dataTableElement = $($('#bmtFilterContainer').data('datatable-id'));
    },
    components: {
      'filter-container': FilterContainer
    },
    methods: {
      updateFilters(filters) {
        this.filters = filters;
      },
      getFilters() {
        return this.filters;
      },
      updateExternalIds(ids) {
        this.dataTableElement.attr('data-external-ids', ids.join(','));
        this.closeFilters();
        this.reloadDataTable();
      },
      clearFilters() {
        this.clearSearchError();
        this.dataTableElement.removeAttr('data-external-ids');
        this.reloadDataTable();
      },
      closeFilters() {
        $(this.$el).closest('.dropdown').removeClass('open');
      },
      reloadDataTable() {
        this.clearSearchError();
        this.dataTableElement.DataTable().ajax.reload();
      },
      handleSearchError(error) {
        $('.repository-table-error').addClass('active').html(error);
      },
      clearSearchError() {
        $('.repository-table-error').removeClass('active').html('');
      }
    }
  });

  // prevent closing of dropdown
  $('#bmtFilterContainer').on('click', (e) => e.stopPropagation());

  // close saved filters dropdown
  $('#bmtFiltersDropdownButton').on('hidden.bs.dropdown', (e) => {
    $('.saved-filters-container').removeClass('open');
  });

  $("#saveBmtFilterForm" )
    .off()
    .on('ajax:before', function() {
      $('#bmt_filter_filters').val(JSON.stringify(bmtFilterContainer.getFilters()));
    })
    .on('ajax:success', function(e, result) {
      bmtFilterContainer.savedFilters.push(result.data);
      $('#modalSaveBmtFilter').modal('hide');
    });

  $.get($('#bmtFilterContainer').data('saved-filters-url'), function(result) {
    bmtFilterContainer.savedFilters = result.data;
  })
};

$('.repository-show').on('click', '.open-save-bmt-modal', () => {
  $('#modalSaveBmtFilter').modal('show');
})
