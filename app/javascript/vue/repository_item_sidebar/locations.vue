<template>
  <div v-if="storageLocations">
    <div v-if="!onlyLocations" class="flex items-center gap-4">
      <h4 data-e2e="e2e-TX-itemCard-locations-title">{{ i18n.t('repositories.locations.title', { count: storageLocations.locations.length }) }}</h4>
      <button v-if="permissions.can_manage && storageLocations.enabled"
              @click="openAssignModal = true" class="btn btn-light ml-auto" data-e2e="e2e-BT-itemCard-locations-assignLocation">
        {{ i18n.t('repositories.locations.assign') }}
      </button>
    </div>
    <div class="mb-4">
      <div v-html="storageLocations.placeholder"></div>
    </div>
    <template v-for="(location, index) in storageLocations.locations" :key="location.id">
      <div>
        <div class="sci-divider my-4" v-if="index > 0"></div>
        <div class="flex gap-2 mb-3 items-center">
          <Breadcrumbs :breadcrumbs="location.breadcrumbs" :readOnly="!location.readable" />
          <i v-if="permissions.can_manage && location.metadata.display_type !== 'grid'"
                 @click="unassignRow(location.id, location.positions[0].id)"
                 class="sn-icon sn-icon-unlink-italic-s cursor-pointer ml-auto"></i>
        </div>
        <div v-if="location.metadata.display_type === 'grid'" class="flex items-center gap-2 flex-wrap">
          <div v-for="(position) in location.positions" :key="position.id">
            <div v-if="position.metadata.position" class="flex items-center font-sm gap-1 uppercase bg-sn-grey-300 rounded pl-1.5 pr-2">
              {{ formatPosition(position.metadata.position) }}
              <i v-if="permissions.can_manage"
                 @click="unassignRow(location.id, position.id)"
                 class="sn-icon sn-icon-unlink-italic-s cursor-pointer"></i>
            </div>
          </div>
        </div>
      </div>
    </template>
    <Teleport to="body">
      <AssignModal
        v-if="openAssignModal"
        assignMode="assign"
        :selectedRow="row.id"
        :selectedRowName="row.name"
        @close="openAssignModal = false; reloadStorageLocations()"
      ></AssignModal>
      <ConfirmationModal
        :title="i18n.t('storage_locations.show.unassign_modal.title')"
        :description="i18n.t('storage_locations.show.unassign_modal.description_single')"
        confirmClass="btn btn-danger"
        :confirmText="i18n.t('storage_locations.show.unassign_modal.button')"
        ref="unassignStorageLocationModal"
      ></ConfirmationModal>
    </Teleport>
  </div>
</template>

<script>
import AssignModal from '../storage_locations/modals/assign.vue';
import ConfirmationModal from '../shared/confirmation_modal.vue';
import Breadcrumbs from '../shared/breadcrumbs.vue';
import axios from '../../packs/custom_axios.js';

import {
  storage_location_path,
  unassign_rows_storage_location_path,
  storage_locations_repository_repository_row_path
} from '../../routes.js';

export default {
  name: 'RepositoryItemLocations',
  props: {
    row: Object,
    repository: Object,
    permissions: { type: Object, default: () => ({}) },
    onlyLocations: {
      type: Boolean,
      default: false
    }
  },
  components: {
    AssignModal,
    ConfirmationModal,
    Breadcrumbs
  },
  data() {
    return {
      openAssignModal: false,
      storageLocations: null
    };
  },
  watch: {
    'row.id': {
      immediate: true,
      handler() {
        this.loadStorageLocations();
      }
    }
  },
  methods: {
    containerUrl(id) {
      return storage_location_path(id);
    },
    formatPosition(position) {
      if (position) {
        return `${this.numberToLetter(position[0])}${position[1]}`;
      }
      return '';
    },
    loadStorageLocations() {
      if (!this.repository?.id || !this.row?.id) return;

      axios.get(storage_locations_repository_repository_row_path(this.repository.id, this.row.id))
        .then((response) => {
          this.storageLocations = response.data;
        });
    },
    reloadStorageLocations() {
      this.loadStorageLocations();
      if (window.StorageLocationsContainer) {
        window.StorageLocationsContainer.$refs.container.reloadingTable = true;
      }
    },
    numberToLetter(number) {
      return String.fromCharCode(96 + number);
    },
    async unassignRow(locationId, rowId) {
      const ok = await this.$refs.unassignStorageLocationModal.show();
      if (ok) {
        axios.post(unassign_rows_storage_location_path({ id: locationId }), { ids: [rowId] })
          .then(() => {
            this.reloadStorageLocations();
          });
      }
    }
  }
};
</script>
