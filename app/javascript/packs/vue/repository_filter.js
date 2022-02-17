/* global I18n */

import TurbolinksAdapter from 'vue-turbolinks';
import Vue from 'vue/dist/vue.esm';
import FilterContainer from '../../vue/repository_filter/container.vue';

Vue.use(TurbolinksAdapter);
Vue.prototype.i18n = window.I18n;

const DEFAULT_FILTERS = [
  {
    id: 1,
    column: {
      data_type: 'RepositoryMyModuleValue',
      id: 'assigned',
      name: I18n.t('repositories.table.assigned_tasks')
    },
    data: { operator: 'any_of' },
    isBlank: true
  },
  {
    id: 2,
    column: {
      data_type: 'RepositoryTextValue',
      id: 'row_id',
      name: I18n.t('repositories.table.id')
    },
    data: { operator: 'contains' },
    isBlank: true
  },
  {
    id: 3,
    column: {
      data_type: 'RepositoryTextValue',
      id: 'row_name',
      name: I18n.t('repositories.table.row_name')
    },
    data: { operator: 'contains' },
    isBlank: true
  },
  {
    id: 4,
    column: {
      data_type: 'RepositoryDateTimeValue',
      id: 'added_on',
      name: I18n.t('repositories.table.added_on')
    },
    data: { operator: 'equal_to' },
    isBlank: true
  },
  {
    id: 5,
    column: {
      data_type: 'RepositoryUserValue',
      id: 'added_by',
      name: I18n.t('repositories.table.added_by')
    },
    data: { operator: 'any_of' },
    isBlank: true
  }
];

window.repositoryFilterObject = null;
window.initRepositoryFilter = () => {
  Vue.prototype.dateFormat = $('#filterContainer').data('date-format')
  const defaultColumns = [
    { id: 'assigned', name: I18n.t('repositories.table.assigned_tasks'), data_type: 'RepositoryMyModuleValue' },
    { id: 'row_id', name: I18n.t('repositories.table.id'), data_type: 'RepositoryTextValue' },
    { id: 'row_name', name: I18n.t('repositories.table.row_name'), data_type: 'RepositoryTextValue' },
    { id: 'added_on', name: I18n.t('repositories.table.added_on'), data_type: 'RepositoryDateTimeValue' },
    { id: 'added_by', name: I18n.t('repositories.table.added_by'), data_type: 'RepositoryUserValue' },
    { id: 'archived_by', name: I18n.t('repositories.table.archived_by'), data_type: 'RepositoryUserValue' },
    { id: 'archived_on', name: I18n.t('repositories.table.archived_on'), data_type: 'RepositoryDateTimeValue' }
  ];
  const repositoryFilterContainer = new Vue({
    el: '#filterContainer',
    data: () => ({
      filters: [],
      defaultFilters: DEFAULT_FILTERS,
      columns: [],
      my_modules: [],
      canManageFilters: $('#filterContainer').data('can-manage-filters'),
      savedFilters: [],
      filterName: null
    }),
    created() {
      this.dataTableElement = $($('#filterContainer').data('datatable-id'));
    },

    components: {
      'filter-container': FilterContainer
    },
    computed: {
      filtersJSON() {
        return this.filters.filter((f) => !f.isBlank).map((f) => ({
          repository_column_id: f.column.id,
          operator: f.data.operator,
          parameters: f.data.parameters
        }));
      }
    },
    methods: {
      updateFilters(filters) {
        this.filters = filters;
      },
      applyFilters() {
        this.dataTableElement
            .attr('data-repository-filter-json', JSON.stringify({ filter_elements: this.filtersJSON }));

        $('#repository_table_filter_elements_json').val(JSON.stringify(this.filtersJSON));

        if (this.filtersJSON.length > 0) {
          $('#saveRepositoryFilters').removeClass('hidden');
        }

        $('#filterContainer .dropdown-selector-container').removeClass('open');
        $('#filtersDropdownButton').removeClass('open');
        $('#filtersDropdownButton').toggleClass('active-filters', this.filtersJSON.length > 0);
        $('.repository-table-error').removeClass('active').html('');
        this.reloadDataTable();
      },
      clearFilters() {
        this.filters = [];
        this.filterName = null;
        this.dataTableElement.removeAttr('data-repository-filter-json');
        $('#modalSaveRepositoryTableFilter').data('repositoryTableFilterId', null);
        $('#saveRepositoryFilters').addClass('hidden');
        $('#overwriteFilterLink').addClass('hidden');
      },
      reloadDataTable() {
        this.dataTableElement.DataTable().ajax.reload();
      },
      updateCurrentFilterName(name) {
        this.filterName = name;
      }
    }
  });

  $.get($('#filterContainer').data('my-modules-url'), (data) => {
    repositoryFilterContainer.my_modules = data.data;
  });

  $.get($('#filterContainer').data('columns-url'), (data) => {
    const combinedColumns = data.response.concat(defaultColumns);
    repositoryFilterContainer.columns = combinedColumns.sort((a, b) => a.name > b.name ? 1 : -1);
  });

  $.get($('#filterContainer').data('saved-filters-url'), (data) => {
    repositoryFilterContainer.savedFilters = data.data;
  });

  $('#filterContainer').on('click', (e) => {
    $('#filterContainer .dropdown-selector-container').removeClass('open')
    e.stopPropagation();
  });

  $('#filtersDropdownButton').on('show.bs.dropdown', () => {
    $('#filtersColumnsDropdown, #savedFiltersContainer').removeClass('open');
  });

  window.repositoryFilterObject = repositoryFilterContainer;
};
