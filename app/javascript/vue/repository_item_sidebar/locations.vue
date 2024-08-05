<template>
  <div v-if="repositoryRow">
    <div class="flex items-center gap-4">
      <h4>{{ i18n.t('repositories.locations.title', { count: repositoryRow.storage_locations.locations.length }) }}</h4>
      <button v-if="repositoryRow.permissions.can_manage && repositoryRow.storage_locations.enabled"
              @click="openAssignModal = true" class="btn btn-light ml-auto">
        {{ i18n.t('repositories.locations.assign') }}
      </button>
    </div>
    <template v-for="(location, index) in repositoryRow.storage_locations.locations" :key="location.id">
      <div>
        <div class="sci-divider my-4" v-if="index > 0"></div>
        <div class="flex items-center gap-2 mb-3">
          {{ i18n.t('repositories.locations.container') }}:
          <a :href="containerUrl(location.id)">{{ location.name }}</a>
          <span v-if="location.metadata.display_type !== 'grid'">
            ({{ location.positions.length }})
          </span>
        </div>
        <div v-if="location.metadata.display_type === 'grid'" class="flex items-center gap-2 flex-wrap">
          <div v-for="(position) in location.positions" :key="position.id">
            <div v-if="position.metadata.position" class="flex items-center font-sm gap-1 uppercase bg-sn-grey-300 rounded pl-1.5 pr-2">
              {{ formatPosition(position.metadata.position) }}
              <i v-if="repositoryRow.permissions.can_manage" class="sn-icon sn-icon-unlink-italic-s cursor-pointer"></i>
            </div>
          </div>
        </div>
      </div>
    </template>
    <Teleport to="body">
      <AssignModal
        v-if="openAssignModal"
        assignMode="assign"
        :selectedRow="repositoryRow.id"
        @close="openAssignModal = false; $emit('reloadRow')"
      ></AssignModal>
    </Teleport>
  </div>
</template>

<script>
import AssignModal from '../storage_locations/modals/assign.vue';
import {
  storage_location_path
} from '../../routes.js';

export default {
  name: 'RepositoryItemLocations',
  props: {
    repositoryRow: Object,
    repository: Object
  },
  components: {
    AssignModal
  },
  data() {
    return {
      openAssignModal: false
    };
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
    numberToLetter(number) {
      return String.fromCharCode(96 + number);
    }
  }
};
</script>
