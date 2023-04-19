<template>
  <div class="sci-input-container">
    <input
      @input="updateFilterData"
      class="sci-input-field"
      type="text"
      name="structure"
      v-model="structure"
      :placeholder="i18n.t('repositories.show.bmt_search.filters.types.monomerSubstructureSearchFilter.placeholder')"
    />
  </div>
</template>

<script>
  import FilterMixin from '../mixins/filter.js'
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
