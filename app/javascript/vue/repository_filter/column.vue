<template>
  <div class="column-filters-element" @click="addFilter">
    <span>{{ column.name }}</span>
  </div>
</template>

<script>
export default {
  name: 'ColumnElement',
  props: {
    column: Object
  },
  methods: {
    addFilter() {
      this.$emit('columns:addFilter', this.column);
    }
  }
};
</script>
