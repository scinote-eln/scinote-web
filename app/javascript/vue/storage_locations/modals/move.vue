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
              <div class="p-2 flex items-center gap-2 cursor-pointer text-sn-blue hover:bg-sn-super-light-grey"
                    @click="selectStorageLocation(null)"
                   :class="{'!bg-sn-super-light-blue': selectedStorageLocationId == null}">
                <i class="sn-icon sn-icon-projects"></i>
                {{ i18n.t('storage_locations.index.move_modal.search_header') }}
              </div>
              <MoveTree :storageLocationTrees="filteredStorageLocationTree" :value="selectedStorageLocationId" @selectStorageLocation="selectStorageLocation" />
            </div>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.cancel') }}</button>
            <button class="btn btn-primary" type="submit">
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
  mixins: [modalMixin, MoveTreeMixin],
  data() {
    return {
      selectedStorageLocationId: null,
      storageLocationTree: [],
      query: ''
    };
  },
  methods: {
    submit() {
      axios.post(this.moveToUrl, {
        destination_storage_location_id: this.selectedStorageLocationId || 'root_storage_location'
      }).then((response) => {
        this.$emit('move');
        HelperModule.flashAlertMsg(response.data.message, 'success');
      }).catch((error) => {
        HelperModule.flashAlertMsg(error.response.data.error, 'danger');
      });
    }
  }
};
</script>
