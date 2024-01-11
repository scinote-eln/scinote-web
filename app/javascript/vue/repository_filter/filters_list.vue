<template>
  <div class="filters-list">
    <FilterElement
      v-for="(filter, index) in filters"
      :key="filter.id"
      :filter.sync="filters[index]"
      :my_modules.sync="my_modules"
      @filter:update="updateFilter"
      @filter:delete="$emit('filter:delete', index)"
    />
  </div>
</template>

<script>
import FilterElement from './filter.vue';

export default {
  name: 'FiltersList',
  props: {
    filters: Array,
    my_modules: Array
  },
  components: { FilterElement },
  methods: {
    updateFilter(value) {
      this.$emit('filter:update', value);
    }
  }
};
</script>
