<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title truncate" id="edit-project-modal-label">
            {{ i18n.t('storage_locations.show.import_modal.title') }}
          </h4>
        </div>
        <div class="modal-body flex flex-col grow">
          <p>
            {{ i18n.t('storage_locations.show.import_modal.description') }}
          </p>
          <h3 class="my-0 text-sn-dark-grey mb-3">
            {{ i18n.t('storage_locations.show.import_modal.export') }}
          </h3>
          <div class="flex gap-4 mb-6">
            <a
              :href="exportUrl"
              target="_blank"
              class="btn btn-secondary btn-sm"
            >
              <i class="sn-icon sn-icon-export"></i>
              {{ i18n.t('storage_locations.show.import_modal.export_button') }}
            </a>
          </div>

          <h3 class="my-0 text-sn-dark-grey mb-3">
            {{ i18n.t('storage_locations.show.import_modal.import') }}
          </h3>
          <DragAndDropUpload
            class="h-60"
            @file:dropped="uploadFile"
            @file:error="handleError"
            @file:error:clear="this.error = null"
            :supportingText="`${i18n.t('storage_locations.show.import_modal.drag_n_drop')}`"
            :supportedFormats="['xlsx']"
          />
        </div>
        <div class="modal-footer">
          <div v-if="error" class="flex flex-row gap-2 my-auto mr-auto text-sn-delete-red">
            <i class="sn-icon sn-icon-alert-warning"></i>
            <div class="my-auto">{{ error }}</div>
          </div>
          <button class="btn btn-secondary" @click="close" aria-label="Close">
            {{ i18n.t('general.cancel') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import DragAndDropUpload from '../../shared/drag_and_drop_upload.vue';
import modalMixin from '../../shared/modal_mixin';
import axios from '../../../packs/custom_axios';
import {
  export_container_storage_location_path,
  import_container_storage_location_path
} from '../../../routes.js';

export default {
  name: 'ImportContainer',
  emits: ['uploadFile', 'close'],
  components: {
    DragAndDropUpload
  },
  mixins: [modalMixin],
  props: {
    containerId: {
      type: Number,
      required: true
    }
  },
  data() {
    return {
      error: null
    };
  },
  computed: {
    exportUrl() {
      return export_container_storage_location_path({
        id: this.containerId
      });
    },
    importUrl() {
      return import_container_storage_location_path({
        id: this.containerId
      });
    }
  },
  methods: {
    handleError(error) {
      this.error = error;
    },
    uploadFile(file) {
      const formData = new FormData();

      // required payload
      formData.append('file', file);

      axios.post(this.importUrl, formData, {
        headers: { 'Content-Type': 'multipart/form-data' }
      })
        .then(() => {
          this.$emit('reloadTable');
          this.close();
        }).catch((error) => {
          this.handleError(error.response.data.message);
        });
    }
  }
};
</script>
