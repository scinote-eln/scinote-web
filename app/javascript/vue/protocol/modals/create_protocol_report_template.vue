<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <form @submit.prevent="submit">
        <div class="modal-content">
          <div class="modal-header">
            <button
              type="button"
              class="close"
              data-dismiss="modal"
              aria-label="Close"
            >
              <i class="sn-icon sn-icon-close"></i>
            </button>
            <h4 class="modal-title truncate !block">
              {{ i18n.t('protocols.report_template.create_modal.title') }}
            </h4>
          </div>
          <div class="modal-body">
            <p class="mb-6">
              {{ i18n.t('protocols.report_template.create_modal.description') }}
            </p>
            <div class="mb-2">
              <label class="sci-label">
                {{ i18n.t('protocols.report_template.create_modal.name_label') }}
              </label>
              <div class="sci-input-container-v2">
                <input
                  type="text"
                  v-model="templateName"
                  :placeholder="i18n.t('protocols.report_template.create_modal.name_placeholder')"
                >
              </div>
              <span v-if="this.errors.name" class="text-sn-coral text-xs">{{ this.errors.name }}</span>
            </div>
            <div class="mb-6">
              <label class="sci-label">
                {{ i18n.t('protocols.report_template.create_modal.import_label') }}
              </label>
              <DragAndDropUpload
                v-if="!attachedFile"
                class="h-60"
                @file:dropped="addFile"
                :supportingText="`${i18n.t('protocols.report_template.create_modal.drag_and_drop_supporting_text')}`"
                :supportedFormats="['odt']"
              />
              <div v-else class="border border-sn-light-grey rounded flex items-center p-2 gap-2">
                <i class="sn-icon sn-icon-result-image text-sn-grey"></i>
                <span class="text-sn-blue">{{ attachedFile?.name }}</span>
                <i class="sn-icon sn-icon-close text-sn-blue ml-auto cursor-pointer" @click="removeFile"></i>
              </div>
            </div>
          </div>
          <div class="modal-footer">
            <button
              type="button"
              class="btn btn-secondary"
              data-dismiss="modal"
            >{{ i18n.t('general.cancel') }}</button>
            <button
              class="btn btn-primary"
              :disabled="submitting || !validObject"
              type="submit"
            >{{ i18n.t('protocols.report_template.create_modal.create_button') }}
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
import modalMixin from '../../shared/modal_mixin.js';
import DragAndDropUpload from '../../shared/drag_and_drop_upload.vue';
import {
  rails_direct_uploads_path,
  protocol_protocol_report_templates_path
} from '../../../routes.js'

export default {
  name: 'CreateProtocolReportTemplateModal',
  props: {
    protocolId: {
      required: true
    }
  },
  components: {
    DragAndDropUpload
  },
  mixins: [modalMixin],
  data() {
    return {
      templateName: '',
      attachedFile: null,
      submitting: false,
      errors: {}
    };
  },
  computed: {
    validObject() {
      this.errors = {};

      if (this.templateName.length > GLOBAL_CONSTANTS.NAME_MAX_LENGTH) {
        this.errors.name = this.i18n.t('protocols.report_template.create_modal.errors.max_length', { max_length: GLOBAL_CONSTANTS.NAME_MAX_LENGTH });
        return false;
      }

      if (!this.templateName || !this.attachedFile) {
        return false;
      }

      return true;
    },
    createUrl() {
      return protocol_protocol_report_templates_path(this.protocolId);
    }
  },
  methods: {
    submit() {
      if (this.submitting) return;

      this.submitting = true;

      const upload = new ActiveStorage.DirectUpload(this.attachedFile, rails_direct_uploads_path());

      upload.create((error, blob) => {
        if (error) {
          this.submitting = false;
          HelperModule.flashAlertMsg(this.i18n.t('attachments.new.general_error'), 'danger');
        } else {
          const signedId = blob.signed_id;
          axios.post(this.createUrl, {
            file: signedId,
            name: this.templateName
          })
            .then((response) => {
              this.submitting = false;
              this.$emit('templateCreated');
            })
            .catch(() => {
              this.submitting = false;
              HelperModule.flashAlertMsg(this.i18n.t('attachments.new.general_error'), 'danger');
            });
        }
      });
    },
    addFile(file) {
      this.attachedFile = file;
    },
    removeImage() {
      this.attachedFile = null;
    }
  }
};
</script>
