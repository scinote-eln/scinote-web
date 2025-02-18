<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <form @submit.prevent="submit">
        <div v-if="overrideWarning" class="modal-content">
          <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
              <i class="sn-icon sn-icon-close"></i>
            </button>
            <h4 class="modal-title truncate !block">
              {{ i18n.t(`storage_locations.show.assign_modal.override.title`) }}
            </h4>
          </div>
          <div class="modal-body">
            <p v-html="i18n.t(`storage_locations.show.assign_modal.override.p_1_html`, {count: this.selectedPositions.filter((p) => p[2].occupied).length})"></p>
            <p>
              {{ i18n.t(`storage_locations.show.assign_modal.override.p_2`) }}
            </p>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" @click="removeOverride = true; submit()">
              {{ i18n.t(`storage_locations.show.assign_modal.override.skip`) }}
            </button>
            <button class="btn btn-danger" @click="confirmOverride = true; submit()">
              {{ i18n.t(`storage_locations.show.assign_modal.override.cta`) }}
            </button>
          </div>
        </div>
        <div v-else class="modal-content">
          <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
              <i class="sn-icon sn-icon-close"></i>
            </button>
            <h4 v-if="selectedPositions.length > 0" class="modal-title truncate !block">
              {{ i18n.t(`storage_locations.show.assign_modal.selected_position_title`, { position: formattedPosition }) }}
            </h4>
            <h4 v-else-if="assignMode === 'assign' && selectedRow && selectedRowName" class="modal-title truncate !block">
              {{ i18n.t(`storage_locations.show.assign_modal.selected_row_title`) }}
            </h4>
            <h4 v-else-if="assignMode === 'move'" class="modal-title truncate !block">
              {{ i18n.t(`storage_locations.show.assign_modal.move_title`, { name: selectedRowName }) }}
            </h4>
            <h4 v-else class="modal-title truncate !block">
              {{ i18n.t(`storage_locations.show.assign_modal.assign_title`) }}
            </h4>
          </div>
          <div class="modal-body">
            <p v-if="selectedRow && selectedRowName" class="mb-4">
              {{ i18n.t(`storage_locations.show.assign_modal.selected_row_description`, { name: selectedRowName }) }}
            </p>
            <h4 v-else-if="assignMode === 'move'" class="modal-title truncate !block">
              {{ i18n.t(`storage_locations.show.assign_modal.move_description`, { name: selectedRowName }) }}
            </h4>
            <p v-else class="mb-4">
              {{ i18n.t(`storage_locations.show.assign_modal.assign_description`) }}
            </p>
            <RowSelector v-if="!selectedRow" @change="this.rowId = $event" class="mb-4"></RowSelector>
            <ContainerSelector v-if="!selectedContainer" @change="this.containerId = $event"></ContainerSelector>
            <PositionSelector
              v-if="containerId && containerId > 0 && !(selectedPositions.length > 0)"
              :key="containerId"
              :selectedContainerId="containerId"
              @change="this.positions = [$event]"></PositionSelector>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.cancel') }}</button>
            <button class="btn btn-primary" type="submit" :disabled="submitting || !validObject">
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
import RowSelector from '../../shared/repository_row_selector.vue';
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
    selectedRowName: String,
    selectedContainer: Number,
    cellId: Number,
    selectedPositions: {
      type: Array,
      default: () => []
    },
    assignMode: String
  },
  mixins: [modalMixin],
  computed: {
    showOverrideWarning() {
      return this.selectedPositions.find((p) => p[2].occupied);
    },
    validObject() {
      return this.rowId && this.containerId && this.containerId > 0;
    },
    createUrl() {
      return storage_location_storage_location_repository_rows_path({
        storage_location_id: this.containerId
      });
    },
    formattedPosition() {
      if (this.selectedPositions.length > 0) {
        const pos = [];
        this.selectedPositions.forEach((p) => {
          pos.push(String.fromCharCode(96 + parseInt(p[0], 10)).toUpperCase() + p[1]);
        });
        return pos.join(', ');
      }
      return '';
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
      positions: this.selectedPositions,
      overrideWarning: false,
      confirmOverride: false,
      removeOverride: false,
      submitting: false
    };
  },
  components: {
    RowSelector,
    ContainerSelector,
    PositionSelector
  },
  methods: {
    submit() {
      if (this.showOverrideWarning && (!this.confirmOverride && !this.removeOverride)) {
        this.overrideWarning = true;
        return;
      }

      if (this.submitting) {
        return;
      }

      this.submitting = true;

      if (this.removeOverride) {
        this.positions = this.positions.filter((p) => !p[2].occupied);
      }

      axios.post(this.actionUrl, {
        repository_row_id: this.rowId,
        positions: this.positions.map((p) => [parseInt(p[0], 10), parseInt(p[1], 10), p[2]])
      }).then(() => {
        this.$emit('assign');
        this.$emit('close');
        this.submitting = false;
      }).catch((error) => {
        this.submitting = false;
        HelperModule.flashAlertMsg(error.response.data.errors.join(', '), 'danger');
      });
    }
  }
};
</script>
