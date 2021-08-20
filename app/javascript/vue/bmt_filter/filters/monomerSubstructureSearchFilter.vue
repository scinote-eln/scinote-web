<template>
  <div class="filter-form">
    <input
      @input="updateFilterData"
      class="form-control"
      type="text"
      name="structure"
      v-model="structure"
      :placeholder="i18n.t('repositories.show.bmt_search.filters.types.monomerSubstructureSearchFilter.placeholder')"
    />
  </div>
</template>

<script>
  import FilterMixin from 'vue/bmt_filter/mixins/filter.js'
  export default {
    name: 'monomerSubstructureSearchFilter',
    mixins: [FilterMixin],
    data() {
      return {
        structure: ""
      }
    }
  }
</script>
