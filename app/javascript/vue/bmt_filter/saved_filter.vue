<template>
  <div class="saved-filter-element">
    {{ saved_filter.attributes.name }}
    <button class="btn btn-light icon-btn" @click="deleteFilter">
      <i class="fas fa-trash"></i>
    </button>
  </div>
</template>

<script>
  export default {
    name: 'SavedFilterElement',
    props: {
      saved_filter: Object
    },
    methods: {
      deleteFilter() {
        let filter = this
        $.ajax({
          url: this.saved_filter.attributes.delete_url,
          type: 'DELETE',
          dataType: 'json',
          success: function() {
            filter.$emit('saved_filter:delete')
          }
        });
      }
    }
  }
</script>
</script>
