<template>
  <div v-if="repositoryRow">
    <div class="flex items-center gap-4">
      <h4 data-e2e="e2e-TX-itemCard-locations-title">{{ i18n.t('repositories.locations.title', { count: repositoryRow.locations.length }) }}</h4>
      <button class="btn btn-light" data-e2e="e2e-BT-itemCard-assignLocation">
        {{ i18n.t('repositories.locations.assign') }}
      </button>
    </div>
    <template v-for="(location, index) in repositoryRow.locations" :key="location.id">
      <div>
        <div class="sci-divider my-4" v-if="index > 0"></div>
        <div class="flex items-center gap-2 mb-3">
          {{ i18n.t('repositories.locations.container') }}:
          <a :href="containerUrl(location.id)">{{ location.name }}</a>
        </div>
        <div class="flex items-center gap-2 flex-wrap">
          <div v-for="(position) in location.positions" :key="position.id">
            <div v-if="position.metadata.position" class="flex items-center font-sm gap-1 uppercase bg-sn-grey-300 rounded pl-1.5 pr-2">
              {{ formatPosition(position.metadata.position) }}
              <i class="sn-icon sn-icon-unlink-italic-s cursor-pointer"></i>
            </div>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>

<script>
import {
  storage_location_path
} from '../../routes.js';

export default {
  name: 'RepositoryItemLocations',
  props: {
    repositoryRow: Object,
    repository: Object
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
      return String.fromCharCode(97 + number);
    }
  }
};
</script>
