<template>
  <div class="filter-form">
    <input
      @input="updateFilterData"
      class="form-control"
      type="text"
      name="monomerType"
      v-model="monomerType"
      :placeholder="i18n.t('repositories.show.bmt_search.filters.types.monomerTypeFilter.placeholder')"
    />
  </div>
</template>

<script>
  import FilterMixin from 'vue/bmt_filter/mixins/filter.js'
  export default {
    name: 'monomerTypeFilter',
    mixins: [FilterMixin],
    data() {
      return {
        monomerType: ""
      }
    }
  }
</script>
