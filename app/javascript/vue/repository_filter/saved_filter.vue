<template>
  <div class="saved-filters-element">
    <span class="saved-filter-name" @click="loadFilters">{{ savedFilter.attributes.name }}</span>
    <button v-if="canManageFilters" class="btn btn-light icon-btn" @click="deleteFilter">
      <i :title="i18n.t('repositories.show.filters.delete_saved_filter')" class="sn-icon sn-icon-delete"></i>
    </button>
  </div>
</template>

<script>
import axios from '../../packs/custom_axios';

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
      axios.delete(this.savedFilter.attributes.delete_url).then(() => {
        this.$emit('savedFilter:delete');
      }).catch(() => {
        HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
      });
    }
  }
};
</script>
