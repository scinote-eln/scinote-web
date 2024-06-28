<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog flex" role="document" :class="{'!w-[900px]': showingInfo}">
      <div v-if="showingInfo" class="w-[300px] shrink-0 h-full bg-sn-super-light-grey p-6 rounded-s text-sn-dark-grey">
        <h3 class="my-0 mb-4">{{ this.i18n.t('repositories.import_records.info_sidebar.title') }}</h3>
        <div v-for="i in 4" :key="i" class="flex gap-3 mb-4">
          <span class="btn btn-secondary icon-btn !text-sn-black !pointer-events-none">
            <i class="sn-icon"
               :class="i18n.t(`repositories.import_records.info_sidebar.elements.element${i - 1}.icon`)"
            ></i>
          </span>
          <div>
            <div class="font-bold mb-2">{{ i18n.t(`repositories.import_records.info_sidebar.elements.element${i - 1}.label`) }}</div>
            <div>{{ i18n.t(`repositories.import_records.info_sidebar.elements.element${i - 1}.subtext`) }}</div>
          </div>
        </div>
        <div class="flex gap-3 mb-4 items-center">
          <span class="btn btn-secondary icon-btn !text-sn-black !pointer-events-none">
            <i class="sn-icon sn-icon-open"></i>
          </span>
          <a :href="i18n.t('repositories.import_records.info_sidebar.elements.element4.linkTo')" class="font-bold" target="_blank">
            {{ i18n.t('repositories.import_records.info_sidebar.elements.element4.label') }}
          </a>
        </div>
      </div>
      <div class="modal-content grow flex flex-col" :class="{'!rounded-s-none': showingInfo}">
        <div class="modal-header gap-4">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close" data-e2e="e2e-BT-newInventoryModal-close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <button class="btn btn-light btn-sm mr-auto" @click="showingInfo = !showingInfo">
            <i class="sn-icon sn-icon-help-s"></i>
            {{ i18n.t('repositories.import_records.steps.step1.helpText') }}
          </button>
          <h4 class="modal-title truncate !block !mr-0" id="edit-project-modal-label" data-e2e="e2e-TX-newInventoryModal-title">
            {{ i18n.t('repositories.import_records.steps.step1.title') }}
          </h4>
        </div>
        <div class="modal-body flex flex-col grow">
          <p class="text-sn-dark-grey">
            {{ this.i18n.t('repositories.import_records.steps.step1.subtitle') }}
          </p>
          <h3 class="my-0 text-sn-dark-grey mb-3">
            {{ i18n.t('repositories.import_records.steps.step1.exportTitle') }}
          </h3>
          <div class="flex gap-4 mb-6">
            <button class="btn btn-secondary btn-sm" @click="$emit('changeStep', 'ExportModal')">
              <i class="sn-icon sn-icon-export"></i>
              {{ i18n.t('repositories.import_records.steps.step1.exportFullInvBtnText') }}
            </button>
            <a :href="params.attributes.urls.export_empty_repository" target="_blank" class="btn btn-secondary btn-sm">
              <i class="sn-icon sn-icon-export"></i>
              {{ i18n.t('repositories.import_records.steps.step1.exportEmptyInvBtnText') }}
            </a>
          </div>

          <h3 class="my-0 text-sn-dark-grey mb-3">
            {{ i18n.t('repositories.import_records.steps.step1.importTitle') }}
          </h3>
          <DragAndDropUpload
            class="h-60"
            @file:dropped="uploadFile"
            @file:error="handleError"
            @file:error:clear="this.error = null"
            :supportingText="`${i18n.t('repositories.import_records.steps.step1.dragAndDropSupportingText')}`"
            :supportedFormats="['xlsx', 'csv', 'xls', 'txt', 'tsv']"
          />
        </div>
        <div class="modal-footer">
          <div v-if="error" class="flex flex-row gap-2 my-auto mr-auto text-sn-delete-red">
            <i class="sn-icon sn-icon-alert-warning"></i>
            <div class="my-auto">{{ error }}</div>
          </div>
          <div v-if="exportInventoryMessage" class="flex flex-row gap-2 my-auto mr-auto text-sn-alert-green">
            <i class="sn-icon sn-icon-check"></i>
            <div class="my-auto">{{ exportInventoryMessage }}</div>
          </div>
          <button class="btn btn-secondary" @click="close" aria-label="Close">
            {{ i18n.t('repositories.import_records.steps.step1.cancelBtnText') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import DragAndDropUpload from '../../../shared/drag_and_drop_upload.vue';
import modalMixin from '../../../shared/modal_mixin';
import axios from '../../../../packs/custom_axios';

export default {
  name: 'UploadStep',
  emits: ['uploadFile', 'close'],
  components: {
    DragAndDropUpload
  },
  mixins: [modalMixin],
  props: {
    params: {
      type: Object,
      required: true
    }
  },
  data() {
    return {
      showingInfo: false,
      error: null,
      parseSheetUrl: null,
      exportInventoryMessage: null
    };
  },
  methods: {
    handleError(error) {
      this.error = error;
    },
    uploadFile(file) {
      const formData = new FormData();

      // required payload
      formData.append('file', file);

      axios.post(this.params.attributes.urls.parse_sheet, formData, {
        headers: { 'Content-Type': 'multipart/form-data' }
      })
        .then((response) => {
          this.$emit('uploadFile', { ...this.params, ...response.data, file_name: file.name });
        }).catch((error) => {
          this.handleError(error.response.data.error);
        });
    }
  }
};
</script>
