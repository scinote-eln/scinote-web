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
      <FilterElement v-for="(filter, index) in filters" :key="filter.id" :filter.sync="filters[index]" @delete:filter="filters.splice(index, 1)"></FilterElement>
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
        filters: [],
        i18n: I18n
      }
    },
    props: {
      container: Object
    },
    components: { FilterElement },
    methods: {
      addFilter: function() {
        var id;

        if (this.filters.length > 0) {
          id = this.filters[this.filters.length - 1].id + 1
        } else {
          id = 1
        };

        this.filters.push({
          id: id
        });
      },
      clearAllFilters: function() {
        this.filters = []
      }
    }
  }
 </script>
