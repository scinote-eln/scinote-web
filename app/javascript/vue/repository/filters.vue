<template>
  <div>
    <GeneralDropdown ref="filtersDropdown" position="right" @open="loadFilters">
      <template v-slot:field>
        <button class="btn btn-light btn-black icon-btn" data-e2e="e2e-DD-forms-builder-editField-options">
          <i class="sn-icon sn-icon-filter"></i>
          <span v-if="activeFilter" class="absolute top-1 right-1 w-1.5 h-1.5 rounded-full bg-sn-alert-passion"></span>
        </button>
      </template>
      <template v-slot:flyout>
        <div class="w-[360px]">
          <div @click="openFiltersModal" class="flex items-center gap-2 p-3 hover:bg-sn-super-light-grey cursor-pointer">
            <i class="sn-icon sn-icon-new-task"></i>
            {{ i18n.t('repositories.show.filters.create_new_filter') }}
          </div>
          <template v-if="activeFilter || savedFilters.length">
            <hr class="m-0">
            <div v-if="activeFilter && !activeFilter.id" class="flex items-center p-3 gap-1 bg-sn-super-light-blue">
              <span>{{ i18n.t('repositories.show.filters.active_filter') }}</span>
              <button class="btn btn-light icon-btn ml-auto" @click="openSaveFilterModal">
                <i class="sn-icon sn-icon-save"></i>
              </button>
            </div>
            <div v-for="(filter, index) in savedFilters" :key="filter.id"
                 class="flex items-center py-2 px-3 gap-1 hover:bg-sn-super-light-grey cursor-pointer"
                 :class="{ 'bg-sn-super-light-blue': activeFilter && activeFilter.id === filter.id }"
            >
              <div class="grow h-10 leading-10" @click="loadFilter(filter)">{{ filter.attributes.name }}</div>
              <button class="btn btn-light icon-btn ml-auto" @click="editFilters(filter)">
                <i class="sn-icon sn-icon-edit"></i>
              </button>
              <button class="btn btn-light icon-btn" @click="deleteFilter(filter)">
                <i class="sn-icon sn-icon-delete"></i>
              </button>
            </div>
            <template v-if="activeFilter">
              <hr class="m-0">
              <div class="flex items-center p-3 gap-1 cursor-pointer hover:bg-sn-super-light-grey" @click="clearFilters">
                <i class="sn-icon sn-icon-close"></i>
                <span>{{ i18n.t('repositories.show.filters.clear_filter') }}</span>
              </div>
            </template>
          </template>
        </div>
      </template>
    </GeneralDropdown>
    <teleport to="#repositoryShowContainer">
      <FiltersModal
        v-if="openModal"
        :params="params"
        :editFilter="editFilter"
        @applyFilters="applyFilters"
        @saveFilter="updateFilter"
        @close="openModal = false; editFilter = null"
      ></FiltersModal>
      <SaveFilterModal
        v-if="openSaveModal"
        :activeFilter="activeFilter"
        :repositoryId="params.repositoryId"
        @close="openModal = false"
      ></SaveFilterModal>
    </teleport>
  </div>
</template>

<script>
import GeneralDropdown from '../shared/general_dropdown.vue';
import FiltersModal from './modals/filters.vue';
import SaveFilterModal from './modals/save_filter.vue';
import axios from '../../packs/custom_axios.js';

import {
  repository_repository_table_filters_path,
  repository_repository_table_filter_path
 } from '../../routes.js';

export default {
  name: 'RepositoryFilters',
  components: {
    GeneralDropdown,
    FiltersModal,
    SaveFilterModal
  },
  props: {
    params: Object
  },
  data() {
    return {
      openModal: false,
      openSaveModal: false,
      activeFilter: null,
      editFilter: null,
      savedFilters: []
    }
  },
  methods: {
    openFiltersModal() {
      this.openModal = true;
      this.$refs.filtersDropdown.closeMenu();
    },
    openSaveFilterModal() {
      this.openSaveModal = true
      this.$refs.filtersDropdown.closeMenu();
    },
    applyFilters(filters) {
      this.openModal = false;
      this.activeFilter = {
        id: null,
        filters: filters
      }
      this.$emit('dtEvent', 'applyFilters', filters)
    },
    loadFilters() {
      axios.get(repository_repository_table_filters_path(this.params.repositoryId)).then((response) => {
        this.savedFilters = response.data.data
      }).catch(() => {
        HelperModule.flashAlertMsg(I18n.t('general.error'), 'danger');
      })
    },
    loadFilter(filter) {
      axios.get(filter.attributes.show_url).then((response) => {
        const filter = response.data

        const filters = [];
        const rawFilters = filter.data.attributes.default_columns.concat((filter.included || []).map((f) => f.attributes));
        rawFilters.forEach((f) => {
          filters.push({
            repository_column_id: f.repository_column_id,
            operator: f.operator,
            parameters: f.parameters
          });
        });

        this.activeFilter = {
          id: filter.data.id,
          filters: filters
        }

        this.$emit('dtEvent', 'applyFilters', filters)
      })
    },
    editFilters(filter) {
      axios.get(filter.attributes.show_url).then((response) => {
        this.editFilter = response.data;
        this.openFiltersModal();
      })
    },
    deleteFilter(filter) {
      axios.delete(filter.attributes.delete_url).then(() => {
        this.loadFilters()
        if (this.activeFilter && this.activeFilter.id === filter.id) {
          this.clearFilters();
        }
      }).catch(() => {
        HelperModule.flashAlertMsg(I18n.t('general.error'), 'danger');
      })
    },
    clearFilters() {
      this.activeFilter = null
      this.$emit('dtEvent', 'applyFilters', [])
    },
    updateFilter(id, filterName, newFilters) {
      const params = {
        repository_table_filter: {
          name: filterName,
          repository_table_filter_elements_json: JSON.stringify(newFilters)
        }
      }

      this.openModal = false;
      this.editFilter = null;

      axios.patch(repository_repository_table_filter_path(this.params.repositoryId, id), params).then(() => {
        this.loadFilters()
        this.$emit('dtEvent', 'applyFilters', newFilters)
      }).catch(() => {
        HelperModule.flashAlertMsg(I18n.t('general.error'), 'danger');
      })
    }
  }
}
</script>
