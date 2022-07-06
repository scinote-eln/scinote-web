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
            <div class="title" @click="$refs.fileSelector.click()">
              <i class="fas fa-upload"></i>
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
          <div class="divider" v-if="step.attributes.marvinjs_enabled || step.attributes.wopi_enabled">
            {{ i18n.t("protocols.steps.attachments.file_modal.or") }}
          </div>
          <div class="integrations-container">
            <div class="integration-block marvinjs" v-if="step.attributes.marvinjs_enabled">
              <a
                class="new-marvinjs-upload-button btn btn-light"
                :data-object-id="step.id"
                :data-marvin-url="step.attributes.marvinjs_context.marvin_js_asset_url"
                data-object-type="Step"
                @click="openMarvinJsModal"
              >
                <span class="new-marvinjs-upload-icon">
                  <img :src="step.attributes.marvinjs_context.icon"/>
                </span>
                {{ i18n.t('marvinjs.new_button') }}
              </a>
            </div>
            <div class="integration-block wopi" v-if="step.attributes.wopi_enabled">
              <a @click="openWopiFileModal" class="create-wopi-file-btn btn btn-light">
                <img :src="step.attributes.wopi_context.icon"/>
                {{ i18n.t('assets.create_wopi_file.button_text') }}
              </a>
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button type='button' class='btn btn-default' @click="cancel">
            {{ i18n.t('general.cancel') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
 <script>
  import StorageUsage from '../storage_usage.vue'

  export default {
    name: 'fileModal',
    props: {
      step: Object
    },
    data() {
      return {
        dragingFile: false
      }
    },
    components: {StorageUsage},
    mounted() {
      $(this.$refs.modal).modal('show');
      MarvinJsEditor.initNewButton('.new-marvinjs-upload-button', () => {
        this.$emit('attachmentsChanged');
        this.$nextTick(this.cancel);
      });
      $(this.$refs.modal).on('hidden.bs.modal', () => {
        global.removeEventListener('paste', this.onImageFilePaste, false);
        this.$emit('cancel');
      });
      global.addEventListener('paste', this.onImageFilePaste, false);
    },
    methods: {
      cancel() {
        $(this.$refs.modal).modal('hide');
      },
      onImageFilePaste (pasteEvent) {
        if (pasteEvent.clipboardData !== false) {
          let items = pasteEvent.clipboardData.items
          for (let i = 0; i < items.length; i += 1) {
            if (items[i].type.indexOf('image') !== -1) {
              this.$emit('copyPasteImageModal', items[i]);
              $(this.$refs.modal).modal('hide');
              return
            }
          }
        }
      },
      dropFile(e) {
        if (e.dataTransfer && e.dataTransfer.files.length) {
          $(this.$refs.modal).modal('hide');
          this.$emit('files', e.dataTransfer.files);
        }
      },
      uploadFiles() {
        $(this.$refs.modal).modal('hide');
        this.$emit('files', this.$refs.fileSelector.files);
      },
      openMarvinJsModal() {
        // hide regular file modal
        $(this.$refs.modal).modal('hide');
      },
      openWopiFileModal() {
        // hide regular file modal
        $(this.$refs.modal).modal('hide');

        // handle legacy wopi file modal
        let $wopiModal = $('#new-office-file-modal')
        $wopiModal.find('#element_id').val(this.step.id);
        $wopiModal.find('#element_type').val('Step');
        $wopiModal.modal('show');

        $wopiModal.find('form').on('ajax:success',
          (_e, data, status) => {
            if (status === 'success') {
              $wopiModal.modal('hide');
              this.$emit('attachmentUploaded', data);

              // cancel and remove regular file modal
              this.$nextTick(() => this.cancel());
            } else {
              HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
            }
          }
        );
      }
    }
  }
</script>
