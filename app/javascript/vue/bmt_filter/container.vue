<template>
  <div class="filter-container">
    <div class="header">
      <div class="title">
        {{ i18n.t('repositories.show.bmt_search.title') }}
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

  export default {
    name: 'FilterContainer',
    data() {
      return {
        filters: []
      }
    },
    props: {
      container: Object
    },
    components: { FilterElement },
    computed: {
      searchJSON() {
        return this.filters.map((f) => f.data);
      }
    },
    methods: {
      addFilter() {
        let id;
        if (this.filters.length > 0) {
          id = this.filters[this.filters.length - 1].id + 1
        } else {
          id = 1
        };
        this.filters.push({ id: id, data: { type: "fullSequenceFilter" } });
      },
      updateFilter(filter) {
        this.filters.find((f) => f.id === filter.id).data = filter.data;
      },
      clearAllFilters() {
        this.filters = [];
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
