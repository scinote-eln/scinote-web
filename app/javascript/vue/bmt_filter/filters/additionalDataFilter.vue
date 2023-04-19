<template>
  <div class="filter-form">
    <div class="sci-input-container">
      <DropdownSelector
        :options="additionalDataAttributes"
        :selectorId="`bmtFilterType${this._uid}`"
        @dropdown:changed="updateAttribute"
      />
    </div>
    <div class="sci-input-container">
      <input
        @input="updateFilterData"
        class="sci-input-field"
        type="text"
        name="value"
        v-model="value"
      />
    </div>
  </div>
</template>

<script>
  import DropdownSelector from '../../shared/dropdown_selector.vue'
  import FilterMixin from '../mixins/filter.js'

  export default {
    name: 'additionalDataFilter',
    mixins: [FilterMixin],
    components: {
      DropdownSelector
    },
    props: {
      additionalDataAttributes: Array,
      filterId: Number
    },
    computed: {
      attributeOptions() {
        return this.additionalDataAttributes.map(option => {
          return {label: option, value: option}
        })
      }
    },
    data() {
      return {
        attribute: null,
        value: null
      }
    },
    methods: {
      updateAttribute(attribute) {
        this.attribute = attribute;
        this.updateFilterData();
      }
    }
  }
</script>
