<template>
  <div class="filter-form">
    <input
      @input="updateFilterData"
      class="form-control"
      type="text"
      name="sequence"
      v-model="sequence"
      :placeholder="i18n.t('repositories.show.bmt_search.filters.types.fullSequenceFilter.placeholder')"
    />
    <div>
      <label>
        <div class="sci-checkbox-container">
          <input
            @change="updateFilterData"
            class="sci-checkbox"
            type="checkbox"
            v-model="derivativesIncluded"
          />
          <label class="sci-checkbox-label"></label>
        </div>
        <span class="checkbox-label">
          {{ i18n.t('repositories.show.bmt_search.filters.types.fullSequenceFilter.derivatives_included') }}
        </span>
      </label>
    </div>
  </div>
</template>

<script>
  import FilterMixin from 'vue/bmt_filter/mixins/filter.js'
  export default {
    name: 'fullsequenceFilter',
    mixins: [FilterMixin],
    data() {
      return {
        sequence: "",
        derivativesIncluded: false
      }
    }
  }
</script>
