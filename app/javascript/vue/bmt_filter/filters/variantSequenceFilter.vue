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
        <div class="sci-input-container">
            <label for="distance">{{ i18n.t('repositories.show.bmt_search.filters.types.variantSequenceFilter.distance') }}</label>
            <input class="sci-input-field" @input="updateFilterData" type="text" v-model="distance" />
        </div>
        <label class="distance-attribute">
          <input
            @change="updateFilterData"
            type="radio"
            v-model="distanceType"
            value="EXACT"
          />
          <span>{{ i18n.t('repositories.show.bmt_search.filters.types.variantSequenceFilter.exact') }}</span>
        </label>
        <label class="distance-attribute">
          <input
            @change="updateFilterData"
            type="radio"
            v-model="distanceType"
            value="MAX"
          />
          <span>{{ i18n.t('repositories.show.bmt_search.filters.types.variantSequenceFilter.maximum') }}</span>
        </label>
      </label>
    </div>
  </div>
</template>

<script>
  import FilterMixin from 'vue/bmt_filter/mixins/filter.js'
  export default {
    name: 'variantSequenceFilter',
    mixins: [FilterMixin],
    data() {
      return {
        sequence: "",
        distance: null,
        distanceType: "EXACT"
      }
    }
  }
</script>
