<template>
  <div v-if="dataLoaded">
    <div v-if="storageLocationsTree.length > 0">
      <div class="mb-4">
        <div class="sci-input-container-v2 left-icon">
          <input type="text"
                  v-model="query"
                  class="sci-input-field"
                  ref="input"
                  autofocus="true"
                  :placeholder=" i18n.t('storage_locations.index.move_modal.placeholder.find_storage_locations')" />
          <i class="sn-icon sn-icon-search"></i>
        </div>
      </div>
      <div class="max-h-80 overflow-y-auto">
        <div class="p-2 flex items-center gap-2 cursor-pointer text-sn-blue hover:bg-sn-super-light-grey"
              @click="selectStorageLocation(null)"
              :class="{'!bg-sn-super-light-blue': selectedStorageLocationId == null}">
          <i class="sn-icon sn-icon-projects"></i>
          {{ i18n.t('storage_locations.index.move_modal.search_header') }}
        </div>
        <MoveTree
          :storageLocationsTree="filteredStorageLocationsTree"
          :moveMode="moveMode"
          :value="selectedStorageLocationId"
          @selectStorageLocation="selectStorageLocation" />

      </div>
    </div>
    <div v-else class="py-2 text-sn-dark-grey" v-html="i18n.t('storage_locations.index.move_modal.no_results')"></div>
  </div>
</template>

<script>
import MoveTreeMixin from '../move_tree_mixin';

export default {
  name: 'ContainerSelector',
  mixins: [MoveTreeMixin],
  data() {
    return {
      container: true,
      moveMode: 'containers'
    };
  },
  watch: {
    selectedStorageLocationId() {
      this.$emit('change', this.selectedStorageLocationId);
    }
  }
};
</script>
