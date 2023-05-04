<template>
  <div class="sci-input-container">
    <input
      @input="updateFilterData"
      class="sci-input-field"
      type="text"
      name="monomerType"
      v-model="monomerType"
      :placeholder="i18n.t('repositories.show.bmt_search.filters.types.monomerTypeFilter.placeholder')"
    />
  </div>
</template>

<script>
  import FilterMixin from '../mixins/filter.js'
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
