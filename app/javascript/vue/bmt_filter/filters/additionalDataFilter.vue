<template>
  <div class="filter-form">
    <div class="form-select">
      <select @change="updateFilterData" v-model="attribute">
        <option
          v-for="attribute in additionalDataAttributes"
          :key="attribute.name" :value="attribute.name">
            {{ attribute.name }}
        </option>
      </select>
    </div>
    <input
      @input="updateFilterData"
      class="form-control"
      type="text"
      name="value"
      v-model="value"
    />
  </div>
</template>

<script>
  import FilterMixin from 'vue/bmt_filter/mixins/filter.js'
  export default {
    name: 'additionalDataFilter',
    mixins: [FilterMixin],
    props: {
      additionalDataAttributes: Array
    },
    data() {
      return {
        attribute: null,
        value: null
      }
    }
  }
</script>
