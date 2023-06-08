<template>
  <div class="filter-container">
    <b class='filter-title'>Filter</b>
    <div class="filter-element">
      <div class="form-group filter-action">
        <div class="sci-input-container">
          <DropdownSelector
            :options="typeOptions"
            :selectorId="`bmtFilter${this.filter.id}`"
            @dropdown:changed="updateFilterType"
          />
        </div>
        <component
          v-if="filter.data"
          :is="filter.data.type"
          @filter:updateData="updateFilter"
          :additionalDataAttributes="additionalDataAttributes"
          :currentData="filter.data" />
      </div>
      <div class="filter-remove">
        <button class="btn btn-light icon-btn " @click="$emit('filter:delete')">
          <i class="sn-icon sn-icon-delete"></i>
        </button>
      </div>
      <hr>
    </div>
  </div>
</template>

<script>
  // Filter types
  import additionalDataFilter from './filters/additionalDataFilter.vue'
  import entityTypeFilter from './filters/entityTypeFilter.vue'
  import monomerTypeFilter from './filters/monomerTypeFilter.vue'
  import subsequenceFilter from './filters/subsequenceFilter.vue'
  import variantSequenceFilter from './filters/variantSequenceFilter.vue'
  import fullsequenceFilter from './filters/fullsequenceFilter.vue'
  import monomerSubstructureSearchFilter from './filters/monomerSubstructureSearchFilter.vue'
  import cidFilter from './filters/cidFilter.vue'

  // Other components
  import DropdownSelector from '../shared/dropdown_selector.vue'

  export default {
    props: {
      filter: Object,
      additionalDataAttributes: Array
    },
    data() {
      return {
        types: [
          'additionalDataFilter',
          'entityTypeFilter',
          'monomerTypeFilter',
          'subsequenceFilter',
          'variantSequenceFilter',
          'fullsequenceFilter',
          'monomerSubstructureSearchFilter',
          'cidFilter'
        ]
      }
    },
    components: {
      additionalDataFilter,
      entityTypeFilter,
      monomerTypeFilter,
      subsequenceFilter,
      variantSequenceFilter,
      fullsequenceFilter,
      monomerSubstructureSearchFilter,
      cidFilter,
      DropdownSelector
    },
    computed: {
      typeOptions() {
        return this.types.map(option => {
          return {label: this.i18n.t(`repositories.show.bmt_search.filters.types.${option}.name`), value: option}
        })
      }
    },
    methods: {
      updateFilterType(type) {
        this.$emit(
          'filter:update',
          {
            id: this.filter.id,
            data: { type: type }
          }
        );
      },
      updateFilter(data) {
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
