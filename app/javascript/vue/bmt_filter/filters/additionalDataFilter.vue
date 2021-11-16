<template>
  <div class="filter-form">
    <div class="sci-input-container">
      <select @change="updateFilterData" v-model="attribute" class="sci-input-field">
        <option
          v-for="attribute in additionalDataAttributes"
          :key="attribute.name" :value="attribute.name">
            {{ attribute.name }}
        </option>
      </select>
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
