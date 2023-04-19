<template>
  <div class="filter-form">
    <input
      @input="updateFilterData"
      class="form-control"
      type="text"
      name="cid"
      v-model="cid"
      :placeholder="i18n.t('repositories.show.bmt_search.filters.types.cidFilter.placeholder')"
    />
  </div>
</template>

<script>
  import FilterMixin from '../mixins/filter.js'
  export default {
    name: 'cidFilter',
    mixins: [FilterMixin],
    data() {
      return {
        cid: ""
      }
    }
  }
</script>
