<template>
  <div class="sci-input-container">
    <input
      @input="updateFilterData"
      class="sci-input-field"
      type="text"
      name="sequence"
      v-model="sequence"
      :placeholder="i18n.t('repositories.show.bmt_search.filters.types.variantSequenceFilter.placeholder')"
    />
    <div>
      <label class="field-suboption">
        <div class="sci-input-container distance-input-container">
            <label for="distance">{{ i18n.t('repositories.show.bmt_search.filters.types.variantSequenceFilter.distance') }}</label>
            <input class="sci-input-field" @input="updateFilterData" type="text" v-model="distance" />
        </div>
        <label class="distance-attribute">
          <span class="sci-radio-container">
            <input
              @change="updateFilterData"
              type="radio"
              class="sci-radio"
              v-model="distanceType"
              value="EXACT"
            />
            <label class="sci-radio-label"></label>
          </span>
          <span>{{ i18n.t('repositories.show.bmt_search.filters.types.variantSequenceFilter.exact') }}</span>
        </label>
        <label class="distance-attribute">
          <span class="sci-radio-container">
            <input
              @change="updateFilterData"
              type="radio"
              class="sci-radio"
              v-model="distanceType"
              value="MAX"
            />
            <label class="sci-radio-label"></label>
          </span>
          <span>{{ i18n.t('repositories.show.bmt_search.filters.types.variantSequenceFilter.maximum') }}</span>
        </label>
      </label>
    </div>
  </div>
</template>

<script>
  import FilterMixin from '../mixins/filter.js'
  export default {
    name: 'variantSequenceFilter',
    mixins: [FilterMixin],
    data() {
      return {
        sequence: "",
        distance: 3,
        distanceType: "EXACT"
      }
    }
  }
</script>
