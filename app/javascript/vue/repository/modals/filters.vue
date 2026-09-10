<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title truncate !block" id="filters-modal-label">
            {{ i18n.t('repositories.show.filters.title') }}
          </h4>
        </div>
        <div class="modal-body">
          <div class="filters-container">
            <template v-if="editFilter">
              <div class="mb-6" >
                <span class="text-sn-grey mb-2">
                  {{ i18n.t('repositories.show.filters.filter_name') }}
                </span>
                <div class="sci-input-container-v2">
                  <input type="text" class="sci-input-field" v-model="filterName">
                </div>
              </div>
            </template>
            <div class="filters-list">
              <FilterElement
                v-for="(filter, index) in filters"
                :key="filter.id"
                :filter="filter"
                :repositoryId="params.repositoryId"
                :my_modules="myModules"
                :filtersCount="filters.length"
                @filter:update="updateFilter"
                @filter:delete="deleteFilter(index)"
              />
            </div>
            <div class="flex justify-center items-center mt-3">
              <GeneralDropdown ref="columnsDropdown" position="right">
                <template v-slot:field>
                  <button class="btn btn-light prevent-shrink" >
                    <i class="sn-icon sn-icon-new-task"></i>
                    {{ i18n.t('repositories.show.filters.add_filter') }}
                  </button>
                </template>
                <template v-slot:flyout>
                  <div class="max-h-[400px] overflow-auto">
                    <div v-for="(column, index) in columns"
                        :key="column.id"
                        class="p-3 hover:bg-sn-super-light-grey"
                        @click="addFilter(column)"
                    >
                      {{ column.name }}
                    </div>
                  </div>
                </template>
              </GeneralDropdown>
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn btn-secondary clear-filters-btn prevent-shrink ml-auto" @click="close" data-e2e="e2e-BT-invInventoryFilterCO-clear">
            {{ i18n.t('general.cancel') }}
          </button>
          <button v-if="editFilter" class="btn btn-primary clear-filters-btn prevent-shrink" @click="saveFilter" data-e2e="e2e-BT-invInventoryFilterCO-clear">
            {{ i18n.t('repositories.show.filters.save_filter') }}
          </button>
          <button v-else class="btn btn-primary apply-button prevent-shrink" @click="applyFilters" data-e2e="e2e-BT-invInventoryFilterCO-showResults">
            {{ i18n.t('repositories.show.filters.apply') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>

import modalMixin from '../../shared/modal_mixin';
import FilterElement from '../filters/filter.vue';
import GeneralDropdown from '../../shared/general_dropdown.vue';
import axios from '../../../packs/custom_axios.js';

import {
  describe_all_repository_repository_columns_path,
  assigned_my_modules_repository_path
 } from '../../../routes.js';

export default {
  name: 'FitlersModal',
  components: {
    FilterElement,
    GeneralDropdown
  },
  props: {
    params: Object,
    editFilter: Object
  },
  data: () => ({
    filters: [],
    columns: [],
    myModules: [],
    filterName: ''
  }),
  created() {
    if (!this.editFilter) {
      this.filters = this.defaultFilters;
    }
    this.loadColumns();
    this.loadMyModules();
  },
  computed: {
    defaultColumns() {
      return [
        { id: 'assigned', name: I18n.t('repositories.table.assigned_tasks'), data_type: 'RepositoryMyModuleValue' },
        { id: 'row_id', name: I18n.t('repositories.table.id'), data_type: 'RepositoryTextValue' },
        { id: 'row_name', name: I18n.t('repositories.table.row_name'), data_type: 'RepositoryTextValue' },
        { id: 'relationships', name: I18n.t('repositories.table.relationships'), data_type: 'RepositoryRelationshipValue' },
        { id: 'added_on', name: I18n.t('repositories.table.added_on'), data_type: 'RepositoryDateTimeValue' },
        { id: 'added_by', name: I18n.t('repositories.table.added_by'), data_type: 'RepositoryUserValue' },
        { id: 'archived_by', name: I18n.t('repositories.table.archived_by'), data_type: 'RepositoryUserValue' },
        { id: 'archived_on', name: I18n.t('repositories.table.archived_on'), data_type: 'RepositoryDateTimeValue' }
      ]
    },
    formattedFilters() {
      return this.filters.filter((f) => !f.isBlank).map((f) => ({
        repository_column_id: f.column.id,
        operator: f.data.operator,
        parameters: f.data.parameters
      }));
    },
    defaultFilters() {
      return [
        {
          id: 1,
          column: {
            data_type: 'RepositoryNonEmptyTextValue',
            id: 'row_name',
            name: I18n.t('repositories.table.row_name')
          },
          data: { operator: 'contains' },
          isBlank: true
        }
      ];
    }
  },
  mixins: [modalMixin],
  methods: {
    applyFilters() {
      this.$emit('applyFilters', this.formattedFilters)
    },
    loadColumns() {
      axios.get(describe_all_repository_repository_columns_path(this.params.repositoryId)).then(response => {
        const combinedColumns = response.data.response.concat(this.defaultColumns);
        this.columns = combinedColumns.sort((a, b) => (a.name > b.name ? 1 : -1));

        if (this.editFilter) {
          this.filterName = this.editFilter.data.attributes.name;

          const filters = [];
          const rawFilters = this.editFilter.data.attributes.default_columns.concat((this.editFilter.included || []).map((f) => f.attributes));
          let id = 0;
          rawFilters.forEach((f) => {
            filters.push({
              id,
              column: this.columns.find((c) => c.id == f.repository_column_id),
              isBlank: false,
              data: {
                operator: f.operator,
                parameters: f.parameters
              }
            });
            id++;
          });
          this.filters = filters;
        }
      })
    },
    loadMyModules() {
      axios.get(assigned_my_modules_repository_path(this.params.repositoryId)).then(response => {
        this.myModules = response.data.data;
      })
    },
    addFilter(column) {
      this.$refs.columnsDropdown.closeMenu();
      const id = this.filters.length ? this.filters[this.filters.length - 1].id + 1 : 1;
      this.filters.push({
        id, column, isBlank: true, data: {}
      });
    },
    updateFilter(filter) {
      const index = this.filters.findIndex((f) => f.id === filter.id);
      this.filters[index].data = filter.data;
      this.filters[index].isBlank = filter.isBlank;
    },
    saveFilter() {
      this.$emit('saveFilter', this.editFilter.data.id, this.filterName, this.formattedFilters)
    },
    deleteFilter(index) {
      this.filters.splice(index, 1);
    }
  }
};
</script>
