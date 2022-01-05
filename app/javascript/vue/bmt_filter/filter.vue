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
          <i class="fas fa-trash"></i>
        </button>
      </div>
      <hr>
    </div>
  </div>
</template>

<script>
  import additionalDataFilter from 'vue/bmt_filter/filters/additionalDataFilter.vue'
  import entityTypeFilter from 'vue/bmt_filter/filters/entityTypeFilter.vue'
  import monomerTypeFilter from 'vue/bmt_filter/filters/monomerTypeFilter.vue'
  import subsequenceFilter from 'vue/bmt_filter/filters/subsequenceFilter.vue'
  import variantSequenceFilter from 'vue/bmt_filter/filters/variantSequenceFilter.vue'
  import fullsequenceFilter from 'vue/bmt_filter/filters/fullsequenceFilter.vue'
  import monomerSubstructureSearchFilter from 'vue/bmt_filter/filters/monomerSubstructureSearchFilter.vue'
  import DropdownSelector from 'vue/shared/dropdown_selector.vue'

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
          'monomerSubstructureSearchFilter'
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
      updateFilter(value) {
        this.$emit(
          'filter:update',
          {
            id: this.filter.id,
            data: value
          }
        );
      }
    }
  }
</script>
