<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <form @submit.prevent="submit">
        <div class="modal-content">
          <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
              <i class="sn-icon sn-icon-close"></i>
            </button>
            <h4 class="modal-title truncate !block">
              {{ i18n.t('storage_locations.index.move_modal.title', { name: this.selectedObject.name }) }}
            </h4>
          </div>
          <div class="modal-body">
            <div class="mb-4">{{ i18n.t('storage_locations.index.move_modal.description', { name: this.selectedObject.name }) }}</div>
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
              <div class="p-2 flex items-center gap-2 "
                   @click="selectStorageLocation(null)"
                   :class="{
                     '!bg-sn-super-light-blue': selectedStorageLocationId == null,
                     'cursor-pointer text-sn-blue hover:bg-sn-super-light-grey': movableToRoot
                   }">
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
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.cancel') }}</button>
            <button class="btn btn-primary" :disabled="submitting || !validContainer" type="submit">
              {{ i18n.t('general.move') }}
            </button>
          </div>
        </div>
      </form>
    </div>
  </div>
</template>

<script>
/* global HelperModule */

import axios from '../../../packs/custom_axios.js';
import modalMixin from '../../shared/modal_mixin';
import MoveTreeMixin from './move_tree_mixin';

export default {
  name: 'NewProjectModal',
  props: {
    selectedObject: Array,
    moveToUrl: String
  },
  created() {
    this.teamId = this.selectedObject.team_id;
  },
  computed: {
    validContainer() {
      return (this.selectedStorageLocationId && this.selectedStorageLocationId > 0) || this.selectedStorageLocationId === null;
    }
  },
  mixins: [modalMixin, MoveTreeMixin],
  data() {
    return {
      selectedStorageLocationId: null,
      storageLocationsTree: [],
      teamId: null,
      query: '',
      moveMode: 'locations',
      submitting: false
    };
  },
  methods: {
    submit() {
      this.submitting = true;

      axios.post(this.moveToUrl, {
        destination_storage_location_id: this.selectedStorageLocationId || 'root_storage_location'
      }).then((response) => {
        this.$emit('move');
        this.submitting = false;
        HelperModule.flashAlertMsg(response.data.message, 'success');
      }).catch((error) => {
        this.submitting = false;
        HelperModule.flashAlertMsg(error.response.data.error, 'danger');
      });
    }
  }
};
</script>
