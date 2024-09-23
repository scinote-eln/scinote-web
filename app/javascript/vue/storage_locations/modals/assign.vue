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
              {{ i18n.t(`storage_locations.show.assign_modal.${assignMode}_title`) }}
            </h4>
          </div>
          <div class="modal-body">
            <p class="mb-4">
              {{ i18n.t(`storage_locations.show.assign_modal.${assignMode}_description`) }}
            </p>
            <RowSelector v-if="!selectedRow" @change="this.rowId = $event" class="mb-4"></RowSelector>
            <ContainerSelector v-if="!selectedContainer" @change="this.containerId = $event"></ContainerSelector>
            <PositionSelector
              v-if="containerId && !selectedPosition"
              :key="containerId"
              :selectedContainerId="containerId"
              @change="this.position = $event"></PositionSelector>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.cancel') }}</button>
            <button class="btn btn-primary" type="submit">
              {{ i18n.t(`storage_locations.show.assign_modal.${assignMode}_action`) }}
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
import RowSelector from './assign/row_selector.vue';
import ContainerSelector from './assign/container_selector.vue';
import PositionSelector from './assign/position_selector.vue';
import {
  storage_location_storage_location_repository_rows_path,
  move_storage_location_storage_location_repository_row_path,

} from '../../../routes.js';

export default {
  name: 'NewProjectModal',
  props: {
    selectedRow: Number,
    selectedContainer: Number,
    cellId: Number,
    selectedPosition: Array,
    assignMode: String
  },
  mixins: [modalMixin],
  computed: {
    createUrl() {
      return storage_location_storage_location_repository_rows_path({
        storage_location_id: this.containerId
      });
    },
    moveUrl() {
      return move_storage_location_storage_location_repository_row_path(this.containerId, this.cellId);
    },
    actionUrl() {
      return this.assignMode === 'assign' ? this.createUrl : this.moveUrl;
    }
  },
  data() {
    return {
      rowId: this.selectedRow,
      containerId: this.selectedContainer,
      position: this.selectedPosition
    };
  },
  components: {
    RowSelector,
    ContainerSelector,
    PositionSelector
  },
  methods: {
    submit() {
      axios.post(this.actionUrl, {
        repository_row_id: this.rowId,
        metadata: { position: this.position?.map((pos) => parseInt(pos, 10)) }
      }).then(() => {
        this.$emit('close');
      }).catch((error) => {
        HelperModule.flashAlertMsg(error.response.data.errors.join(', '), 'danger');
      });
    }
  }
};
</script>
