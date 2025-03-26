<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title truncate !block" id="edit-project-modal-label">
            {{ i18n.t('storage_locations.index.find_row_modal.title') }}
          </h4>
        </div>
        <div class="modal-body">
          <p>{{ i18n.t('storage_locations.index.find_row_modal.description') }}</p>
          <RowSelector
            @change="this.rowId = $event"
            @repositoryChange="this.repositoryId = $event"
            class="mb-4"
          ></RowSelector>
          <div v-if="loading" class="relative h-32">
            <hr class="my-4">
            <div class="flex absolute top-0 left-0 items-center justify-center w-full flex-grow h-full z-10">
              <img src="/images/medium/loading.svg" alt="Loading" />
            </div>
          </div>
          <template v-if="row" >
            <hr class="my-4">
            <Locations v-if="row.storage_locations.locations.length > 0" :repositoryRow="row" :onlyLocations="true"></Locations>
            <span v-else class="text-sn-grey-700">
              {{ i18n.t('storage_locations.index.find_row_modal.no_results') }}
            </span>
          </template>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-primary" data-dismiss="modal">{{ i18n.t('general.close') }}</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>

import modalMixin from '../../shared/modal_mixin';
import RowSelector from '../../shared/repository_row_selector.vue';
import axios from '../../../packs/custom_axios.js';
import Locations from '../../repository_item_sidebar/locations.vue';
import {
  repository_repository_row_path
} from '../../../routes.js';

export default {
  name: 'FindRowModal',
  mixins: [modalMixin],
  components: {
    RowSelector,
    Locations
  },
  data() {
    return {
      rowId: null,
      repositoryId: null,
      row: null,
      loading: false
    };
  },
  watch: {
    rowId() {
      if (this.rowId) {
        this.row = null;
        this.loadRowInfo();
      }
    }
  },
  methods: {
    rowInfoUrl(rowId) {
      return repository_repository_row_path(this.repositoryId, rowId);
    },
    loadRowInfo() {
      if (this.rowId) {
        this.loading = true;
        axios.get(this.rowInfoUrl(this.rowId))
          .then((response) => {
            this.loading = false;
            this.row = response.data;
          });
      }
    }
  }
};
</script>
