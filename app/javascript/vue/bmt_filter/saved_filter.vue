<template>
  <div class="saved-filter-element">
    {{ savedFilter.attributes.name }}
    <button class="btn btn-light icon-btn" @click="deleteFilter">
      <i class="fas fa-trash"></i>
    </button>
  </div>
</template>

<script>
  export default {
    name: 'SavedFilterElement',
    props: {
      savedFilter: Object
    },
    methods: {
      deleteFilter() {
        let filter = this
        $.ajax({
          url: this.savedFilter.attributes.delete_url,
          type: 'DELETE',
          dataType: 'json',
          success: function() {
            filter.$emit('savedFilter:delete')
          }
        });
      }
    }
  }
</script>
</script>
