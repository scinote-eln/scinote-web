<template>
  <div class="sci-input-container">
    <input
      @input="updateFilterData"
      class="sci-input-field"
      type="text"
      name="sequence"
      v-model="sequence"
      :placeholder="i18n.t('repositories.show.bmt_search.filters.types.subsequenceFilter.placeholder')"
    />
    <div>
      <label class="field-suboption">
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
          {{ i18n.t('repositories.show.bmt_search.filters.types.subsequenceFilter.derivatives_included') }}
        </span>
      </label>
    </div>
  </div>
</template>

<script>
  import FilterMixin from '../mixins/filter.js'
  export default {
    name: 'subsequenceFilter',
    mixins: [FilterMixin],
    data() {
      return {
        sequence: "",
        derivativesIncluded: true
      }
    }
  }
</script>
