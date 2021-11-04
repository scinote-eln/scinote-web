<template>
  <div class="filter-element">
    <div class="form-group filter-action">
      <div class="sci-input-container">
        <select @change="updateFilter({ type: $event.target.value })" v-model="type" :id="'bmtFilter' + this.filter.id">
          <option
            v-for="type in types"
            :key="type.name" :value="type">
              {{ i18n.t('repositories.show.bmt_search.filters.types.' + type + '.name') }}
          </option>
        </select>
      </div>
      <component
        :is="type"
        @filter:updateData="updateFilter"
        :additionalDataAttributes="additionalDataAttributes"
        :currentData="filter.data" />
    </div>
    <div class="filter-remove">
      <button class="btn btn-light icon-btn" @click="$emit('filter:delete')">
        <i class="fas fa-times-circle"></i>
      </button>
    </div>
    <hr>
  </div>
</template>

<script>
  import additionalDataFilter from 'vue/bmt_filter/filters/additionalDataFilter.vue'
  import entityTypeFilter from 'vue/bmt_filter/filters/entityTypeFilter.vue'
  import monomerTypeFilter from 'vue/bmt_filter/filters/monomerTypeFilter.vue'
  import subsequenceFilter from 'vue/bmt_filter/filters/subsequenceFilter.vue'
  import variantSequenceFilter from 'vue/bmt_filter/filters/variantSequenceFilter.vue'
  import fullSequenceFilter from 'vue/bmt_filter/filters/fullSequenceFilter.vue'
  import monomerSubstructureSearchFilter from 'vue/bmt_filter/filters/monomerSubstructureSearchFilter.vue'

  export default {
    props: {
      filter: Object,
      additionalDataAttributes: Array
    },
    data() {
      return {
        type: this.filter.data.type,
        types: [
          'additionalDataFilter',
          'entityTypeFilter',
          'monomerTypeFilter',
          'subsequenceFilter',
          'variantSequenceFilter',
          'fullSequenceFilter',
          'monomerSubstructureSearchFilter'
        ],
        additionaDataAttributes: []
      }
    },
    components: {
      additionalDataFilter,
      entityTypeFilter,
      monomerTypeFilter,
      subsequenceFilter,
      variantSequenceFilter,
      fullSequenceFilter,
      monomerSubstructureSearchFilter
    },
    mounted: function() {
      let filterTypeSelect = `#bmtFilter${this.filter.id}`;
      dropdownSelector.init(filterTypeSelect, {
        noEmptyOption: true,
        singleSelect: true,
        closeOnSelect: true,
        selectAppearance: 'simple',
      });
    },
    methods: {
      updateFilter(data) {
        console.log(1)
        this.$emit(
          'filter:update',
          {
            id: this.filter.id,
            data: data
          }
        );
      }
    }
  }
</script>
