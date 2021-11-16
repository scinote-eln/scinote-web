<template>
  <div class="filter-container">
    <b class='filter-title'>Filter</b>  
    <div class="filter-element">
      <div class="form-group filter-action">
      
        <div class="sci-input-container">
          <DropdownSelector
            :options="prepareTypesOptions()"
            :selectorId="`bmtFilter${this.filter.id}`"
            @dropdown:changed="updateFilter"
          />
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
  import DropdownSelector from 'vue/shared/dropdown_selector.vue'

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
      monomerSubstructureSearchFilter,
      DropdownSelector
    },
    methods: {
      prepareTypesOptions() {
        return this.types.map(option => {
          return {label: this.i18n.t(`repositories.show.bmt_search.filters.types.${option}.name`), value: option}
        })
      },
      updateFilter(value) {
        this.type = value;
        this.$emit(
          'filter:update',
          {
            id: this.filter.id,
            data: {
              type: value
            }
          }
        );
      }
    }
  }
</script>
