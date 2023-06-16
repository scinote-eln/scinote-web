<template>
  <div class="saved-filters-element">
    <span @click="loadFilters">{{ savedFilter.attributes.name }}</span>
    <button v-if="canManageFilters" class="btn btn-light icon-btn" @click="deleteFilter">
      <i class="sn-icon sn-icon-delete"></i>
    </button>
  </div>
</template>

<script>
  export default {
    name: 'SavedFilterElement',
    props: {
      savedFilter: Object,
      canManageFilters: Boolean
    },
    methods: {
      loadFilters() {
        this.$emit('savedFilter:load', this.savedFilter.attributes.filters)
      },
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
