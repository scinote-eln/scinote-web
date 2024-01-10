<template>
  <div id="repository-asset-value-wrapper" class="flex flex-col min-min-h-[46px] h-auto gap-[6px]">
    <div class="flex flex-row justify-between">
      <div class="font-inter text-sm font-semibold leading-5 truncate" :title="colName">
        {{ colName }}
      </div>
      <a v-if="!file_name && (!uploading || error) && canEdit"
        class="btn-text-link font-normal min-w-fit pl-4" @click="openFileChooser">
        {{ i18n.t('repositories.item_card.repository_asset_value.add_asset') }}
      </a>
      <div v-if="file_name && !uploading && canEdit" class="flex whitespace-nowrap gap-4 min-w-fit pl-4">
        <a class="btn-text-link font-normal" @click="openFileChooser">
          {{ i18n.t('general.replace') }}
        </a>
        <a class="btn-text-link font-normal" @click="clearFile">
          {{ i18n.t('general.delete') }}
        </a>
      </div>
    </div>

    <div v-if="!uploading">
      <div v-if="file_name">
        <div class="flex flex-row justify-between">
          <div class="w-full cursor-pointer relative" @mouseover="tooltipShowing = true" @mouseout="tooltipShowing = false">
            <a class="w-full inline-block file-preview-link truncate text-sn-science-blue" :id="modalPreviewLinkId" data-no-turbolink="true"
              data-id="true" data-status="asset-present" :data-preview-url=this?.preview_url :href=this?.url>
              {{ file_name }}
            </a>
            <tooltip-preview v-if="tooltipShowing && medium_preview_url" :id="id" :url="url" :file_name="file_name"
              :preview_url="preview_url" :icon_html="icon_html" :medium_preview_url="medium_preview_url">
            </tooltip-preview>
          </div>
        </div>
      </div>
      <div v-else-if="!error" class="flex flex-row items-center font-inter text-sm font-normal leading-5 justify-between"
        :class="{ 'text-sn-dark-grey': !canEdit, 'text-sn-grey': canEdit }">
        {{ i18n.t('repositories.item_card.repository_asset_value.no_asset') }}
      </div>
    </div>
    <div v-else class="bg-sn-light-grey h-1 w-full rounded-sm">
      <div class="h-full bg-sn-science-blue rounded-sm transition-all duration-1000 ease-sharp" :style="`width: ${progress}%`"></div>
    </div>
    <div v-if="error" class="text-sn-alert-passion font-inter text-sm">
      {{ error }}
    </div>
    <input type="file" ref="fileInput" @change="handleFileChange" style="display: none" />
  </div>
</template>

<script>
import TooltipPreview from './TooltipPreview.vue';

export default {
  name: 'RepositoryAssetvalue',
  components: {
    'tooltip-preview': TooltipPreview
  },
  data() {
    return {
      tooltipShowing: false,
      id: null,
      url: null,
      preview_url: null,
      file_name: null,
      icon_html: null,
      medium_preview_url: null,
      uploading: false,
      progress: 0,
      error: false
    };
  },
  props: {
    data_type: String,
    colId: Number,
    colName: String,
    colVal: Object,
    permissions: Object,
    actions: Object,
    updatePath: String,
    canEdit: { type: Boolean, default: false }
  },
  created() {
    if (!this.colVal) return;

    this.id = this.colVal.id;
    this.url = this.colVal.url;
    this.preview_url = this.colVal.preview_url;
    this.file_name = this.colVal.file_name;
    this.icon_html = this.colVal.icon_html;
    this.medium_preview_url = this.colVal.medium_preview_url;
  },
  computed: {
    modalPreviewLinkId() {
      return `modal_link${this.id}`;
    }
  },
  methods: {
    openFileChooser() {
      this.$refs.fileInput.click();
    },
    handleFileChange(event) {
      if (event.target.files[0]) {
        this.uploadFiles(event.target.files[0]);
      }
    },
    clearFile() {
      this.$refs.fileInput.value = '';
      this.error = '';
      this.updateCell(null);
    },
    uploadFiles(file) {
      this.uploading = true;
      this.progress = 0;
      this.error = '';

      if (file.size > GLOBAL_CONSTANTS.FILE_MAX_SIZE_MB * 1024 * 1024) {
        this.error = I18n.t(
          'repositories.item_card.repository_asset_value.errors.file_too_big',
          { file_size: GLOBAL_CONSTANTS.FILE_MAX_SIZE_MB }
        );
        this.uploading = false;
        return;
      }

      const upload = new ActiveStorage.DirectUpload(
        file,
        this.actions.direct_file_upload_path,
        {
          directUploadWillStoreFileWithXHR: (request) => {
            request.upload.addEventListener('progress', (e) => {
              this.progress = parseInt((e.loaded / e.total) * 100, 10);
            });
          }
        }
      );

      upload.create((error, blob) => {
        if (error) {
          this.error = I18n.t('repositories.item_card.repository_asset_value.errors.upload_failed_general');
          this.uploading = false;
        } else {
          this.updateCell(blob.signed_id);
        }
      });
    },
    updateCell(value) {
      $.ajax({
        type: 'PUT',
        url: this.updatePath,
        data: {
          repository_cells: {
            [this.colId]: value
          }
        },
        success: (result) => {
          const assetRepositoryCell = result?.value;
          this.uploading = false;

          if (assetRepositoryCell) {
            this.id = assetRepositoryCell.id;
            this.url = assetRepositoryCell.url;
            this.preview_url = assetRepositoryCell.preview_url;
            this.file_name = assetRepositoryCell.file_name;
            this.icon_html = assetRepositoryCell.icon_html;
            this.medium_preview_url = assetRepositoryCell.medium_preview_url;
          } else {
            this.file_name = '';
          }
          if ($('.dataTable.repository-dataTable')[0]) $('.dataTable.repository-dataTable').DataTable().ajax.reload(null, false);
        },
        error: () => {
          this.error = I18n.t('repositories.item_card.repository_asset_value.errors.upload_failed_general');
          this.uploading = false;
        }
      });
    }
  }
};
</script>
