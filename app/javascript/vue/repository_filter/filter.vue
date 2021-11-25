<template>
  <div class="filter-container">
    <div class='filter-title'>{{ filter.column.name }}</div>
    <div class="filter-element">
      <div class="filter-body">
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
  import DropdownSelector from 'vue/shared/dropdown_selector.vue'

  export default {
    name: "FilterElement",
    props: {
      filter: Object,
    },
    data() {
      return {}
    },
    components: {
      DropdownSelector
    },
    methods: {
      updateFilter(value) {
      }
    }
  }
</script>
  