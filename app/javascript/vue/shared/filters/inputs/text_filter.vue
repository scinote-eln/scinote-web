<template>
  <div>
    <label>{{ filter.label }}</label>
    <div class="sci-input-container">
      <input  class="sci-input-field"
              type="text"
              :id="filter.key"
              :placeholder="filter.placeholder"
              :value="value"
              @input="update($event.target.value)">
    </div>
  </div>
</template>

<script>
  export default {
    name: 'TextFilter',
    props: {
      filter: { type: Object, required: true },
      value: { type: String }
    },
    methods: {
      update(value) {
        this.$emit('update', { key: this.filter.key, value: value });
      }
    }
  }
</script>
