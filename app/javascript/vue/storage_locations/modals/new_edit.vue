<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <form @submit.prevent="submit">
        <div class="modal-content">
          <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
              <i class="sn-icon sn-icon-close"></i>
            </button>
            <h4 class="modal-title truncate !block" >
              {{ i18n.t(`storage_locations.index.edit_modal.title_${mode}_${editModalMode}`) }}
            </h4>
          </div>
          <div class="modal-body">
            <p v-if="mode == 'create'" class="mb-6">{{ i18n.t(`storage_locations.index.edit_modal.description_create_${editModalMode}`) }}</p>
            <div class="mb-6">
              <label class="sci-label">
                {{ i18n.t(`storage_locations.index.edit_modal.name_label_${editModalMode}`) }}
              </label>
              <div class="sci-input-container-v2">
                <input
                  type="text"
                  v-model="object.name"
                  :placeholder="i18n.t(`storage_locations.index.edit_modal.name_placeholder_${editModalMode}`)"
                >
              </div>
              <span v-if="this.errors.name" class="text-sn-coral text-xs">{{ this.errors.name }}</span>
            </div>
            <div v-if="editModalMode == 'container'" :title="warningBoxNotEmpty" class="mb-6">
              <label class="sci-label">
                {{ i18n.t(`storage_locations.index.edit_modal.dimensions_label`) }}
              </label>
              <div class="flex items-center gap-2 mb-4">
                <div class="sci-radio-container">
                  <input type="radio" class="sci-radio" :disabled="!canChangeGrid" v-model="object.metadata.display_type" name="display_type" value="no_grid" >
                  <span class="sci-radio-label"></span>
                </div>
                <span>{{ i18n.t('storage_locations.index.edit_modal.no_grid') }}</span>
                <i class="sn-icon sn-icon-info text-sn-grey" :title="i18n.t('storage_locations.index.edit_modal.no_grid_tooltip')"></i>
              </div>
              <div class="flex items-center gap-2 mb-4">
                <div class="sci-radio-container">
                  <input type="radio" class="sci-radio" :disabled="!canChangeGrid"  v-model="object.metadata.display_type" name="display_type" value="grid" >
                  <span class="sci-radio-label"></span>
                </div>
                <span>{{ i18n.t('storage_locations.index.edit_modal.grid') }}</span>
                <div class="sci-input-container-v2 !w-28">
                  <input type="number" :disabled="!canChangeGrid"  v-model="object.metadata.dimensions[0]" min="1" max="24">
                </div>
                <i class="sn-icon sn-icon-close-small"></i>
                <div class="sci-input-container-v2 !w-28">
                  <input type="number" :disabled="!canChangeGrid"  v-model="object.metadata.dimensions[1]" min="1" max="24">
                </div>
              </div>
            </div>
            <div class="mb-6">
              <label class="sci-label">
                {{ i18n.t(`storage_locations.index.edit_modal.image_label_${editModalMode}`) }}
              </label>
              <DragAndDropUpload
                v-if="!attachedImage && !object.file_name"
                class="h-60"
                @file:dropped="addFile"
                @file:error="handleError"
                @file:error:clear="this.imageError = null"
                :supportingText="`${i18n.t('storage_locations.index.edit_modal.drag_and_drop_supporting_text')}`"
                :supportedFormats="['jpg', 'png', 'jpeg']"
              />
              <div v-else class="border border-sn-light-grey rounded flex items-center p-2 gap-2">
                <i class="sn-icon sn-icon-result-image text-sn-grey"></i>
                <span class="text-sn-blue">{{ object.file_name || attachedImage?.name }}</span>
                <i class="sn-icon sn-icon-close text-sn-blue ml-auto cursor-pointer" @click="removeImage"></i>
              </div>
            </div>
            <div class="mb-6">
              <label class="sci-label">
                {{ i18n.t(`storage_locations.index.edit_modal.description_label`) }}
              </label>
              <div class="sci-input-container-v2 h-32">
                <textarea
                  ref="description"
                  v-model="object.description"
                  :placeholder="i18n.t(`storage_locations.index.edit_modal.description_placeholder`)"
                ></textarea>
              </div>
              <span v-if="this.errors.description" class="text-sn-coral text-xs">{{ this.errors.description }}</span>
            </div>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.cancel') }}</button>
            <button class="btn btn-primary" :disabled="!validObject" type="submit">
              {{ mode == 'create' ? i18n.t('general.create') : i18n.t('general.save') }}
            </button>
          </div>
        </div>
      </form>
    </div>
  </div>
</template>

<script>
/* global HelperModule SmartAnnotation ActiveStorage GLOBAL_CONSTANTS */

import axios from '../../../packs/custom_axios.js';
import modalMixin from '../../shared/modal_mixin';
import DragAndDropUpload from '../../shared/drag_and_drop_upload.vue';

export default {
  name: 'EditLocationModal',
  props: {
    createUrl: String,
    editModalMode: String,
    directUploadUrl: String,
    editStorageLocation: Object
  },
  components: {
    DragAndDropUpload
  },
  mixins: [modalMixin],
  data() {
    return {
      object: {
        metadata: {
          dimensions: [9, 9],
          display_type: 'grid'
        }
      },
      attachedImage: null,
      imageError: false,
      savingLocaiton: false,
      errors: {}
    };
  },
  computed: {
    mode() {
      return this.editStorageLocation ? 'edit' : 'create';
    },
    canChangeGrid() {
      return !this.object.code || this.object.is_empty;
    },
    warningBoxNotEmpty() {
      if (this.canChangeGrid) {
        return '';
      }
      return this.i18n.t('storage_locations.index.edit_modal.warning_box_not_empty');
    },
    validObject() {
      this.errors = {};

      if (!this.object.name) {
        return false;
      }

      if (this.object.name.length > GLOBAL_CONSTANTS.NAME_MAX_LENGTH) {
        this.errors.name = this.i18n.t('storage_locations.index.edit_modal.errors.max_length', { max_length: GLOBAL_CONSTANTS.NAME_MAX_LENGTH });
        return false;
      }

      if (this.object.description && this.object.description.length > GLOBAL_CONSTANTS.TEXT_MAX_LENGTH) {
        this.errors.description = this.i18n.t('storage_locations.index.edit_modal.errors.max_length', { max_length: GLOBAL_CONSTANTS.TEXT_MAX_LENGTH });
        return false;
      }

      return true;
    }
  },
  created() {
    if (this.editStorageLocation) {
      this.object = this.editStorageLocation;
    }
  },
  mounted() {
    SmartAnnotation.init($(this.$refs.description), false);
    $(this.$refs.modal).on('hidden.bs.modal', this.handleAtWhoModalClose);

    this.object.container = this.editModalMode === 'container';
  },
  methods: {
    submit() {
      if (this.attachedImage) {
        this.uploadImage();
      } else {
        this.saveLocation();
      }
    },
    saveLocation() {
      // Smart annotation fix
      this.object.description = $(this.$refs.description).val();

      if (this.savingLocaiton) {
        return;
      }

      this.savingLocaiton = true;

      if (this.object.code) {
        axios.put(this.object.urls.update, this.object)
          .then(() => {
            this.$emit('tableReloaded');
            HelperModule.flashAlertMsg(this.i18n.t(`storage_locations.index.edit_modal.success_message.edit_${this.editModalMode}`, { name: this.object.name }), 'success');
            this.savingLocaiton = false;
            this.close();
          }).catch((error) => {
            HelperModule.flashAlertMsg(error.response.data.error, 'danger');
            this.savingLocaiton = false;
          });
      } else {
        axios.post(this.createUrl, this.object)
          .then(() => {
            this.$emit('tableReloaded');
            HelperModule.flashAlertMsg(this.i18n.t(`storage_locations.index.edit_modal.success_message.create_${this.editModalMode}`, { name: this.object.name }), 'success');
            this.savingLocaiton = false;
            this.close();
          }).catch((error) => {
            HelperModule.flashAlertMsg(error.response.data.error, 'danger');
            this.savingLocaiton = false;
          });
      }
    },
    handleError() {
    },
    addFile(file) {
      this.attachedImage = file;
    },
    removeImage() {
      this.attachedImage = null;
      this.object.file_name = null;
    },
    uploadImage() {
      const upload = new ActiveStorage.DirectUpload(this.attachedImage, this.directUploadUrl);

      upload.create((error, blob) => {
        if (error) {
          // Handle the error
        } else {
          this.object.signed_blob_id = blob.signed_id;
          this.saveLocation();
        }
      });
    },
    handleAtWhoModalClose() {
      $('.atwho-view.old').css('display', 'none');
    }
  }
};
</script>
