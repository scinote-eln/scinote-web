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
    filter: { type: Object, required: true },
    values: { type: Object }
  },
  data() {
    return {
      value: this.values[this.filter.key]
    };
  },
  watch: {
    value() {
      this.$emit('update', { key: this.filter.key, value: this.value || null });
    }
  }
};
</script>
