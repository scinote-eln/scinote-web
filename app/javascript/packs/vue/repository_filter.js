import TurbolinksAdapter from 'vue-turbolinks';
import Vue from 'vue/dist/vue.esm';
import FilterContainer from '../../vue/repository_filter/container.vue';

Vue.use(TurbolinksAdapter);
Vue.prototype.i18n = window.I18n;

window.initRepositoryFilter = () => {
  Vue.prototype.dateFormat = $('#filterContainer').data('date-format')
  const defaultColumns = [
    { id: 'assigned', name: 'Assigned to task', data_type: 'RepositoryMyModuleValue' },
    { id: 'row_id', name: 'ID', data_type: 'RepositoryTextValue' },
    { id: 'row_name', name: 'Name', data_type: 'RepositoryTextValue' },
    { id: 'added_on', name: 'Added on', data_type: 'RepositoryDateTimeValue' },
    { id: 'added_by', name: 'Added by', data_type: 'RepositoryUserValue' }
  ];
  const repositoryFilterContainer = new Vue({
    el: '#filterContainer',
    data: () => {
      return {
        filters: [],
        columns: [],
        my_modules: []
      };
    },
    created() {
      this.dataTableElement = $($('#filterContainer').data('datatable-id'));
    },
    components: {
      'filter-container': FilterContainer
    },
    computed: {
      filtersJSON() {
        return this.filters.map((f) => {
          return {
            repository_column_id: f.column.id,
            operator: f.operator,
            parameters: { ...f.data, isBlank: f.isBlank }
          }
        });
      }
    },
    methods: {
      updateFilters(filters) {
        this.filters = filters;
      },
      applyFilters() {
        this.dataTableElement.attr('data-repository-filter-json', JSON.stringify(this.filtersJSON));
        $('#filterContainer .dropdown-selector-container').removeClass('open');
        $('#filtersDropdownButton').removeClass('open');
        $('#filtersDropdownButton').addClass('active-filters');
        this.reloadDataTable();
      },
      clearFilters() {
        this.filters = [];
        $('#filtersDropdownButton').removeClass('active-filters');
        this.reloadDataTable();
      },
      reloadDataTable() {
        this.dataTableElement.DataTable().ajax.reload();
      }
    }
  });

  $.get($('#filterContainer').data('my-modules-url'), function(data) {
    repositoryFilterContainer.my_modules = data;
  });

  $.get($('#filterContainer').data('columns-url'), function(data) {
    repositoryFilterContainer.columns = data.response.concat(defaultColumns).sort((a, b) => a.name > b.name ? 1 : -1);
  });

  $('#filterContainer').on('click', (e) => {
    $('#filterContainer .dropdown-selector-container').removeClass('open')
    e.stopPropagation();
  });
};
