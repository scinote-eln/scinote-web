<template>
  <div class="filters-container">
    <div class="header">
      <div id="savedFiltersContainer" class="dropdown saved-filters-container">
        <div class="title" id="savedFilterDropdown">
          Filters
        </div>
      </div>
      <button class="btn btn-light clear-filters-btn">
        <i class="fas fa-times-circle"></i>
        Clear
      </button>
    </div>
    <div class="filters-list">
      <div v-if="filters.length == 0" class="filter-list-notice">
        No filters
      </div>
    </div>
    <div class="footer">
      <button class="btn btn-secondary add-filter">
        <i class="fas fa-plus"></i>
        Add filter
      </button>
      <button class="btn btn-primary">
        Apply
      </button>
    </div>
  </div>
</template>

 <script>
  //import FilterElement from 'vue/repository_filter/filter.vue'

  export default {
    name: 'FilterContainer',
    data() {
      return {
        filters: []
      }
    },
    props: {
      container: Object,
      savedFilters: Array
    },
    created() {
    }
    //components: { FilterElement, SavedFilterElement },
  }
 </script>
