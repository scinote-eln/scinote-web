<template>
  <div class="mb-6 flex gap-2 items-center">
    <span class="sci-checkbox-container">
      <input type="checkbox" v-model="value" class="sci-checkbox" />
      <span class="sci-checkbox-label"></span>
    </span>
    <span class="sci-label">{{ filter.label }}</span>
  </div>
</template>

<script>
  export default {
    name: 'CheckboxFilter',
    props: {
      filter: { type: Object, required: true }
    },
    data: function() {
      return {
        value: false
      }
    },
    watch: {
      value: function() {
        this.$emit('update', { key: this.filter.key, value: this.value });
      }
    },
  }
</script>
