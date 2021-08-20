<template>
  <div class="filter-form">
    <input
      @input="updateFilterData"
      class="form-control"
      type="text"
      name="sequence"
      v-model="sequence"
      :placeholder="i18n.t('repositories.show.bmt_search.filters.types.variantSequenceFilter.placeholder')"
    />
    <div>
      <label>
        <div class="row">
          <div class="col-md-4">
            <label for="distance">{{ i18n.t('repositories.show.bmt_search.filters.types.variantSequenceFilter.distance') }}</label>
            <input class="form-control" @input="updateFilterData" type="text" v-model="distance" />
          </div>
          <div class="col-md-4">
            <label>
              <input
                @change="updateFilterData"
                type="radio"
                v-model="distanceType"
                value="EXACT"
              />
              <span>{{ i18n.t('repositories.show.bmt_search.filters.types.variantSequenceFilter.exact') }}</span>
            </label>
          </div>
          <div class="col-md-4">
            <label>
              <input
                @change="updateFilterData"
                type="radio"
                v-model="distanceType"
                value="MAX"
              />
              <span>{{ i18n.t('repositories.show.bmt_search.filters.types.variantSequenceFilter.maximum') }}</span>
            </label>
          </div>
        </div>
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
