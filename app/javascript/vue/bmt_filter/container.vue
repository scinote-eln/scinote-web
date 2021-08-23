<template>
  <div class="filter-container">
    <div class="header">
      <div class="dropdown savedFilterContainer">
        <div class="title" @click="openSavedFilters()">
          {{ i18n.t('repositories.show.bmt_search.title') }}
          <i class="fas fa-caret-down"></i>
        </div>
        <div class="dropdown-menu saved-filters-container">
          <SavedFilterElement
            v-for="(saved_filter, index) in saved_filters"
            :key="saved_filter.id"
            :saved_filter.sync="saved_filters[index]"
            @saved_filter:delete="saved_filters.splice(index, 1)"
          />
        </div>
      </div>
      <button class="btn btn-light" @click="clearAllFilters">
        <i class="fas fa-times-circle"></i>
        {{ i18n.t('repositories.show.bmt_search.clear_all') }}
      </button>
    </div>
    <div class="filters-list">
      <div v-if="filters.length == 0" class="filter-list-notice">
        {{ i18n.t('repositories.show.bmt_search.no_filters') }}
      </div>
      <FilterElement
          v-for="(filter, index) in filters"
          :key="filter.id"
          :filter.sync="filters[index]"
          @filter:delete="filters.splice(index, 1)"
          @filter:update="updateFilter"
        />
    </div>
    <div class="footer">
      <button class="btn btn-light add-filter" @click="addFilter">
        <i class="fas fa-plus"></i>
        {{ i18n.t('repositories.show.bmt_search.add_filter') }}
      </button>
      <button class="btn btn-primary">
        {{ i18n.t('repositories.show.bmt_search.apply') }}
      </button>
    </div>
  </div>
</template>

 <script>
  import FilterElement from 'vue/bmt_filter/filter.vue'
  import SavedFilterElement from 'vue/bmt_filter/saved_filter.vue'

  export default {
    name: 'FilterContainer',
    data() {
      return {
        filters: []
      }
    },
    props: {
      container: Object,
      saved_filters: Array
    },
    components: { FilterElement, SavedFilterElement },
    computed: {
      searchJSON() {
        return this.filters.map((f) => f.data);
      }
    },
    watch: {
      filters() {
        $('.open-save-bmt-modal').toggleClass('hidden', !this.filters.length)
      }
    },
    methods: {
      addFilter() {
        let id = this.filters.length ? this.filters[this.filters.length - 1].id + 1 : 1
        this.filters.push({ id: id, data: { type: "fullSequenceFilter" } });
      },
      updateFilter(filter) {
        this.filters.find((f) => f.id === filter.id).data = filter.data;
      },
      clearAllFilters() {
        this.filters = [];
      },
      openSavedFilters() {
        $('.savedFilterContainer').toggleClass('open')
      },
      loadFilters(filters) {
        this.clearAllFilters();
        filters.forEach((filter, index) => {
          this.filters.push(
            {
              id: index,
              data: filter
            }
          );
        });
      }
    }
  }
 </script>
