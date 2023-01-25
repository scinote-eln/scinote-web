<template>
  <div class="filters-list">
    <FilterElement
      v-for="(filter, index) in filters"
      :key="filter.id"
      :filter="filters[index]"
      :my_modules="my_modules"
      @filter:update="$emit('update-filter', filter)"
      @filter:delete="$emit('delete-filter', index)"
    />
  </div>
</template>

<script>
// @filter:delete="filters.splice(index, 1)"
  import FilterElement from 'vue/repository_filter/filter.vue'

    export default {
    name: 'FiltersList',
    props: {
      filters: Array,
      my_modules: Array,
    },
    components: {FilterElement},
  }
</script>
