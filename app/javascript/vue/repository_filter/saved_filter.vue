<template>
  <div class="saved-filters-element">
    <span class="saved-filter-name" @click="loadFilters">{{ savedFilter.attributes.name }}</span>
    <button v-if="canManageFilters" class="btn btn-light icon-btn" @click="deleteFilter">
      <i :title="i18n.t('repositories.show.filters.delete_saved_filter')" class="sn-icon sn-icon-delete"></i>
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
      this.$emit('savedFilter:load', this.savedFilter.attributes.show_url);
    },
    deleteFilter() {
      $.ajax({
        url: this.savedFilter.attributes.delete_url,
        type: 'DELETE',
        success: () => {
          this.$emit('savedFilter:delete');
        }
      });
    }
  }
};
</script>
