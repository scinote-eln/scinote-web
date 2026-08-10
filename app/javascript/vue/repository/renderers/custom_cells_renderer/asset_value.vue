<template>
  <div>
    <div v-if="params.data.permissions.manage" class="relative">
      <div v-if="params.value" class="relative flex items-center gap-2 group">
        <a  :href="params.value.value.url"
            class="file-preview-link file-name grow truncate"
            :id="`modal_link${params.value.value.id}`"
            data-no-turbolink="true"
            :data-id="params.value.value.id"
            :data-preview-url="previewUrl"
        >
          {{ params.value.value.file_name }}
        </a>
        <div class="tw-hidden group-hover:block right-0 h-10 w-6 flex items-center justify-center cursor-pointer"
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
        <div class="text-sn-grey-500 cursor-pointer" @click="addFile">
          {{ i18n.t('repositories.table.assets.add_file') }}
        </div>
        <input type="file" ref="fileSelector" class="hidden" @change="uploadFile" />
      </div>
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
import {
  asset_file_preview_path,
} from '../../../../routes.js';



export default {
  name: 'AssetValue',
  props: {
    params: {
      required: true
    }
  },
  data() {
    return {
      uploading: false
    };
  },
  components: {
    ConfirmationModal
  },
  watch: {
    'params.value': () => {
      this.uploading = false;
    }
  },
  computed: {
    previewUrl() {
      return asset_file_preview_path(this.params.value.value.id, { preview: true });
    }
  },
  methods: {
    addFile() {
      this.$refs.fileSelector.click();
    }
  },
  methods: {
    addFile() {
      this.$refs.fileSelector.click();
    },
    uploadFile(event) {
      this.uploading = true;
      this.params.dtComponent.$emit(
        'uploadFile',
        this.params.data,
        this.params.colDef,
        event.target.files[0]
      );
    },
    async deleteFile() {
      const ok = await this.$refs.deleteModal.show();
      if (ok) {
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
