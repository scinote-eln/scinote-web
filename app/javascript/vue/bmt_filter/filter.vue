<template>
  <div class="filter-element">
    <div class="filter-action">
      Filter {{ filter.id }}
    </div>
    <div class="filter-remove">
      <button class="btn btn-light icon-btn" @click="$emit('delete:filter')">
        <i class="fas fa-times-circle"></i>
      </button>
    </div>
  </div>
</template>

<script>
  export default {
    props: {
      filter: Object
    }
  }
</script>
