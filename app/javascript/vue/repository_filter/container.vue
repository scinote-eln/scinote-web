<template>
  <div class="filters-container">
    <div class="header">
      <div id="savedFiltersContainer" class="dropdown saved-filters-container">
        <div class="title" id="savedFilterDropdown">
          {{ i18n.t('repositories.show.filters.title') }}
        </div>
      </div>
      <button class="btn btn-light clear-filters-btn" @click="clearFilters()">
        <i class="fas fa-times-circle"></i>
        {{ i18n.t('repositories.show.filters.clear') }}
      </button>
    </div>
    <div class="filters-list">
      <FilterElement
        v-for="(filter, index) in filters"
        :key="filter.id"
        :filter.sync="filters[index]"
        :my_modules.sync= "my_modules"
        @filter:update="updateFilter"
        @filter:delete="filters.splice(index, 1)"
      />
    </div>
    <div class="footer">
      <div id="filtersColumnsDropdown" class="dropup filters-columns-dropdown" @click="toggleColumnsFilters">
        <button class="btn btn-secondary add-filter" >
          <i class="fas fa-plus"></i>
          {{ i18n.t('repositories.show.filters.add_filter') }}
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
      <button @click="$emit('filters:apply')" class="btn btn-primary apply-button">
        {{ i18n.t('repositories.show.filters.apply') }}
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
      my_modules: Array,
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
        this.filters.push({ id: id, column: column, isBlank: true, data: {} });
      },
      updateFilter(filter) {
        const index = this.filters.findIndex((f) => f.id === filter.id);
        this.filters[index].data = filter.data;
        this.filters[index].isBlank = filter.isBlank;

        this.$emit("filters:update", this.filters);
      },
      clearFilters() {
        this.filters = [];
        this.$emit('filters:clear');
      },
      toggleColumnsFilters() {
        $('#filtersColumnsDropdown').toggleClass('open');
      }
    }
  }
 </script>
