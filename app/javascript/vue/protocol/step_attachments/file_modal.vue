<template>
  <div ref="modal" @keydown.esc="cancel"
       class="modal add-file-modal"
       :class="dragingFile ? 'draging-file' : ''"
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
                data-object-type="Step"
              >
                <span class="new-marvinjs-upload-icon">
                  <img :src="step.attributes.marvinjs_context.icon"/>
                </span>
                {{ i18n.t('marvinjs.new_button') }}
              </a>
            </div>
            <div class="integration-block wopi" v-if="step.attributes.wopi_enabled">
              <a :href="step.attributes.wopi_context.create_wopi"
                 class="create-wopi-file-btn btn btn-light"
                 target="_blank"
                 :data-id="step.id"
                 data-element-type="Step"
              >
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
    mounted() {
      $(this.$refs.modal).modal('show');
    },
    methods: {
      cancel() {
        $(this.$refs.modal).modal('hide');
        this.$emit('cancel');
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
      }
    }
  }
</script>
