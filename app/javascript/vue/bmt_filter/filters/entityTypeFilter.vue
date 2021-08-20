<template>
  <div class="filter-form">
    <input
      @input="updateFilterData"
      class="form-control"
      type="text"
      name="entityType"
      v-model="entityType"
      :placeholder="i18n.t('repositories.show.bmt_search.filters.types.entityTypeFilter.placeholder')"
    />
  </div>
</template>

<script>
  import FilterMixin from 'vue/bmt_filter/mixins/filter.js'
  export default {
    name: 'entityTypeFilter',
    mixins: [FilterMixin],
    data() {
      return {
        entityType: ""
      }
    }
  }
</script>
