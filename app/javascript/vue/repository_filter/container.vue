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
      <FilterElement
        v-for="(filter, index) in filters"
        :key="filter.id"
        :filter.sync="filters[index]"
        @filter:delete="filters.splice(index, 1)"
      />
    </div>
    <div class="footer">
      <div id="filtersColumnsDropdown" class="dropdown filters-columns-dropdown" @click="toggleColumnsFilters">
        <button class="btn btn-secondary add-filter" >
          <i class="fas fa-plus"></i>
          Add filter
        </button>
        <div class="dropdown-menu filters-columns-list">

          <ColumnElement
            v-for="(column, index) in columns"
            :key="column.id"
            :column.sync="columns[index]"
            @columns:addFilter="addFilter"
          />
        </div>
      </div>
      <button class="btn btn-primary">
        Apply
      </button>
    </div>
  </div>
</template>

 <script>
  import ColumnElement from 'vue/repository_filter/column.vue'
  import FilterElement from 'vue/repository_filter/filter.vue'

  export default {
    name: 'FilterContainer',
    data() {
      return {
        filters: []
      }
    },
    props: {
      container: Object,
      savedFilters: Array,
      columns: Array
    },
    created() {
    },
    components: { ColumnElement, FilterElement },
    methods: {
      addFilter(column) {
        const id = this.filters.length ? this.filters[this.filters.length - 1].id + 1 : 1
        this.filters.push({ id: id, column: column, data: {} });
      },
      toggleColumnsFilters() {
        $('#filtersColumnsDropdown').toggleClass('open');
      }
    }
  }
 </script>
