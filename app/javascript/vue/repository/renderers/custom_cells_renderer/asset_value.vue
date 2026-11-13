<template>
  <div>
    <div v-if="canManage" class="relative" :title="mandatoryErrorTitle">
      <div v-if="hasFile" class="relative flex items-center gap-2 group">
        <span v-if="isDraft" class="file-name grow truncate" :title="params.value.value.file_name"
              data-e2e="e2e-TX-itemCard-assetDraftName">
          {{ params.value.value.file_name }}
        </span>
        <a  v-else
            :href="params.value.value.url"
            class="file-preview-link file-name grow truncate"
            :id="`modal_link${params.value.value.id}`"
            data-no-turbolink="true"
            :data-id="params.value.value.id"
            :data-preview-url="previewUrl"
        >
          {{ params.value.value.file_name }}
        </a>
        <div class="opacity-0 pointer-events-none group-hover:opacity-100 group-hover:pointer-events-auto flex right-0 h-10 w-6 shrink-0 items-center justify-center cursor-pointer"
             @click="deleteFile">
          <i class="sn-icon sn-icon-delete"></i>
        </div>
      </div>
      <div v-else-if="uploading">
        <div class="text-sn-grey-500">
          {{ i18n.t('repositories.table.assets.uploading') }}
        </div>
      </div>
      <div v-else>
        <div class="text-sn-grey-500 cursor-pointer"
             :class="addFileClass"
             data-e2e="e2e-BT-itemCard-assetAddFile"
             @click="addFile">
          {{ i18n.t('repositories.table.assets.add_file') }}
        </div>
        <input type="file" ref="fileSelector" class="hidden" @change="uploadFile" @cancel="touch" />
      </div>
      <MandatoryError :show="params.inSidebar && showError" />
    </div>
    <div v-else>
      <div v-if="params.value">
        <a  :href="params.value.value.url"
            class="file-preview-link file-name"
            :id="`modal_link${params.value.value.id}`"
            data-no-turbolink="true"
            :data-id="params.value.value.id"
            :data-preview-url="previewUrl"
        >
          {{ params.value.value.file_name }}
        </a>
      </div>
    </div>
    <teleport to="body">
      <ConfirmationModal
        :title="i18n.t('repositories.modal_delete_asset_value.title')"
        :description="i18n.t('repositories.modal_delete_asset_value.notice_html')"
        confirmClass="btn btn-danger"
        :confirmText="i18n.t('repositories.modal_delete_asset_value.delete')"
        ref="deleteModal"
      ></ConfirmationModal>
    </teleport>
  </div>
</template>

<script>

import ConfirmationModal from '../../../shared/confirmation_modal.vue';
import MandatoryError from './shared/mandatory_error.vue';
import mandatoryCellMixin from './mixins/mandatory_cell.js';
import {
  asset_file_preview_path
} from '../../../../routes.js';

export default {
  name: 'AssetValue',
  mixins: [mandatoryCellMixin],
  props: {
    params: {
      required: true
    }
  },
  data() {
    return {
      uploading: false,
      // File removed from a mandatory cell of a saved item; kept on the server until replaced
      removed: false
    };
  },
  components: {
    ConfirmationModal,
    MandatoryError
  },
  watch: {
    'params.value'() {
      this.uploading = false;
      this.removed = false;
    }
  },
  computed: {
    // A file for a file that is not created yet has not been uploaded.
    isDraft() {
      return !this.params.data.id;
    },
    hasFile() {
      return !!this.params.value && !this.removed;
    },
    isEmpty() {
      return !this.hasFile;
    },
    addFileClass() {
      if (this.showError) return ['border border-solid !border-sn-delete-red rounded', this.params.inSidebar ? 'px-3 py-2' : 'h-10 flex items-center px-1'];
      if (this.params.inSidebar) return 'border border-solid !border-sn-light-grey rounded px-3 py-2';

      return null;
    },
    previewUrl() {
      return asset_file_preview_path(this.params.value.value.id);
    },
    canManage() {
      return this.params?.data?.permissions?.manage || false;
    }
  },
  methods: {
    addFile() {
      this.$refs.fileSelector.click();
    },
    uploadFile(event) {
      const file = event.target.files[0];
      if (!file) return;

      this.uploading = true;
      this.params.dtComponent.$emit(
        'uploadFile',
        this.params.data,
        this.params.colDef,
        file
      );
    },
    async deleteFile() {
      if (this.mandatory && !this.isDraft) {
        this.removed = true;
        this.touch();
        return;
      }

      const ok = this.isDraft || await this.$refs.deleteModal.show();
      if (ok) {
        this.touch();
        this.params.dtComponent.$emit(
          'updateCell',
          this.params.data,
          this.params.colDef,
          null
        );
      }
    }
  }
};
</script>
