<template>
  <div ref="modal" @keydown.esc="cancel"
       class="modal add-file-modal"
       :class="{ 'draging-file' : dragingFile }"
       role="dialog" aria-hidden="true" tabindex="-1">
    <div class="modal-dialog">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <span aria-hidden="true">&times;</span>
          </button>
          <h2 class="modal-title">
            {{ i18n.t("protocols.steps.attachments.file_modal.title") }}
          </h2>
        </div>
        <div class="modal-body">
          <div class="file-drop-zone"
               @drop.prevent="dropFile"
               @dragenter.prevent="dragingFile = true"
               @dragleave.prevent="dragingFile = false"
               @dragover.prevent
          >
            <input type="file" class="hidden" ref=fileSelector @change="uploadFiles" multiple />
            <div class="title btn btn-light" @click="$refs.fileSelector.click()" tabindex="0" @keyup.enter="$refs.fileSelector.click()">
              <i class="sn-icon sn-icon-import"></i>
              {{ i18n.t("protocols.steps.attachments.file_modal.drag_zone_title") }}
            </div>
            <div class="description">
              {{ i18n.t("protocols.steps.attachments.file_modal.drag_zone_description") }}
            </div>
            <StorageUsage v-if="step.attributes.storage_limit" :step="step"/>
            <div class="available-storage"></div>
            <div class="drop-notification">
              {{ i18n.t("protocols.steps.attachments.file_modal.drag_zone_notification", {position: step.attributes.position + 1}) }}
            </div>
          </div>
          <div class="divider" v-if="step.attributes.marvinjs_enabled || step.attributes.wopi_enabled || step.attributes.open_vector_editor_context.new_sequence_asset_url">
            {{ i18n.t("protocols.steps.attachments.file_modal.or") }}
          </div>
          <div class="integrations-container">
            <div class="integration-block wopi" v-if="step.attributes.wopi_enabled">
              <a @click="openWopiFileModal" class="create-wopi-file-btn btn btn-light" tabindex="0" @keyup.enter="openWopiFileModal">
                <img :src="step.attributes.wopi_context.icon"/>
                {{ i18n.t('assets.create_wopi_file.button_text') }}
              </a>
            </div>
            <div class="integration-block" v-if="step.attributes.open_vector_editor_context.new_sequence_asset_url">
              <a @click="openOVEditor" class="open-vector-editor-button btn btn-light">
                <img :src="step.attributes.open_vector_editor_context.icon"/>
                {{ i18n.t('open_vector_editor.new_sequence') }}
              </a>
            </div>
            <div class="integration-block marvinjs" v-if="step.attributes.marvinjs_enabled">
              <a
                class="new-marvinjs-upload-button btn btn-light"
                :data-object-id="step.id"
                :data-marvin-url="step.attributes.marvinjs_context?.marvin_js_asset_url"
                data-object-type="Step"
                @click="openMarvinJsModal"
                tabindex="0"
                @keyup.enter="openMarvinJsModal"
              >
                <span class="new-marvinjs-upload-icon">
                  <img :src="step.attributes.marvinjs_context.icon"/>
                </span>
                {{ i18n.t('marvinjs.new_li_button') }}
              </a>
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button type='button' class='btn btn-secondary' @click="cancel">
            {{ i18n.t('general.cancel') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
import StorageUsage from '../storage_usage.vue';

import WopiFileModal from './mixins/wopi_file_modal.js';

export default {
  name: 'fileModal',
  props: {
    step: Object
  },
  data() {
    return {
      dragingFile: false,
      attachmentsChanged: false
    };
  },
  components: { StorageUsage },
  mixins: [WopiFileModal],
  mounted() {
    $(this.$refs.modal).modal('show');
    MarvinJsEditor.initNewButton('.add-file-modal .new-marvinjs-upload-button', () => {
      this.attachmentsChanged = true;
      $(this.$refs.modal).modal('hide');
    });
    $(this.$refs.modal).on('hidden.bs.modal', () => {
      global.removeEventListener('paste', this.onImageFilePaste, false);

      if (this.attachmentsChanged) {
        this.$emit('attachmentsChanged');
      } else {
        this.cancel();
      }
    });
    global.addEventListener('paste', this.onImageFilePaste, false);
  },
  methods: {
    cancel() {
      $(this.$refs.modal).modal('hide');
      this.$nextTick(() => this.$emit('cancel'));
    },
    onImageFilePaste(pasteEvent) {
      if (pasteEvent.clipboardData !== false) {
        const { items } = pasteEvent.clipboardData;
        for (let i = 0; i < items.length; i += 1) {
          if (items[i].type.indexOf('image') !== -1) {
            this.$emit('copyPasteImageModal', items[i]);
            $(this.$refs.modal).modal('hide');
            return;
          }
        }
      }
    },
    dropFile(e) {
      e.stopPropagation();
      if (e.dataTransfer && e.dataTransfer.files.length) {
        this.$emit('files', e.dataTransfer.files);
        $(this.$refs.modal).modal('hide');
      }
    },
    uploadFiles() {
      this.$emit('files', this.$refs.fileSelector.files);
      $(this.$refs.modal).modal('hide');
      this.$parent.$parent.$nextTick(() => {
        this.$parent.$el.scrollIntoView(false);
      });
    },
    openMarvinJsModal() {
    },
    openWopiFileModal() {
      this.initWopiFileModal(this.step, (_e, data, status) => {
        if (status === 'success') {
          $(this.$refs.modal).modal('hide');
          this.$emit('attachmentUploaded', data);
        } else {
          HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
        }
      });
    },
    openOVEditor() {
      $(this.$refs.modal).modal('hide');
      window.showIFrameModal(this.step.attributes.open_vector_editor_context.new_sequence_asset_url);
    }
  }
};
</script>
