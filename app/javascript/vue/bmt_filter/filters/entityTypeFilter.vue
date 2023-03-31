<template>
  <div class="sci-input-container">
    <input
      @input="updateFilterData"
      class="sci-input-field"
      type="text"
      name="entityType"
      v-model="entityType"
      :placeholder="i18n.t('repositories.show.bmt_search.filters.types.entityTypeFilter.placeholder')"
    />
  </div>
</template>

<script>
  import FilterMixin from '../mixins/filter.js'
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
