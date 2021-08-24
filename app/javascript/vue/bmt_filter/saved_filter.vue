<template>
  <div class="saved-filter-element">
    {{ saved_filter.filter_name }}
    <button class="btn btn-light icon-btn" @click="$emit('saved_filter:delete')">
      <i class="fas fa-trash"></i>
    </button>
  </div>
</template>

<script>
  export default {
    name: 'SavedFilterElement',
    props: {
      saved_filter: Object
    }
  }
</script>
</script>
