<template>
  <div class="ove-wrapper flex flex-col h-screen">
    <div class="ove-header flex justify-between h-14 px-4 py-2">
      <span class="file-name flex items-center ml-3">
        <div class="sci-input-container">
          <input v-model="sequenceName"
                 class="border-sn-grey border-[1px] rounded-[4px] px-2 py-1 w-80 h-10 text-sm font-sans"
                 type="text"
                 :disabled="readOnly"
                 :placeholder="i18n.t('open_vector_editor.sequence_name_placeholder')"/>
        </div>
      </span>
      <div v-if="oveEnabledDaysLeft <= 30" class="flex items-center">
        <i class="mr-1 text-brand-warning sn-icon sn-icon-alert-warning"></i>
        <p v-html="i18n.t('open_vector_editor.trial_expiration_warning_html', { count: oveEnabledDaysLeft })" class="mb-0"></p>
      </div>
      <div class="ove-buttons text-sn-blue">
        <button v-if="!readOnly" @click="saveAndClose" class="btn btn-light font-sans">
          <i class="sn-icon sn-icon-save"></i>
          {{ i18n.t('SaveClose') }}
        </button>
        <button @click="closeModal" class="preview-close btn btn-light icon-btn">
          <i class="sn-icon sn-icon-close"></i>
        </button>
      </div>
    </div>
    <div ref="container" class="ove-container w-full h-full">
    </div>
  </div>
</template>

 <script>
  import axios from 'axios';
  import { blobToBase64 } from '../shared/blobToBase64.js'

  export default {
    name: 'OpenVectorEditor',
    props: {
      fileUrl: { type: String },
      fileName: { type: String },
      updateUrl: { type: String },
      readOnly: { type: Boolean, default: false },
      oveEnabledDaysLeft: { type: Number }
    },
    data() {
      return {
        editor: null,
        sequenceName: null,
        closeAfterSave: false
      }
    },
    watch: {
      sequenceName() {
        if (this.editor && this.editor.getState()) {
          this.editor.updateEditor({
            sequenceData: { ...this.editor.getState().sequenceData, name: this.sequenceName }
          });
        }
      }
    },
    mounted() {
      let editorConfig = {
        onSave: this.saveFile,
        generatePng: true,
        readOnly: this.readOnly
      }

      if (this.readOnly) {
        editorConfig = {
          ...editorConfig,
          showReadOnly: false,
          ToolBarProps: {
            toolList: []
          }
        }
      }

      this.editor = window.createVectorEditor(this.$refs.container, editorConfig);
      this.sequenceName = this.fileName;

      if (this.fileUrl) {
        this.loadFile();
      } else {
        this.editor.updateEditor(
          {
            sequenceData: { circular: true, name: this.sequenceName }
          }
        );
      }
    },
    methods: {
      loadFile() {
        fetch(this.fileUrl).then((response) => response.json()).then(
          (json) => this.editor.updateEditor(
            {
              sequenceData: json
            }
          )
        );
      },
      saveAndClose() {
        this.closeAfterSave = close;
        document.querySelector('[data-test=saveTool]').click();
      },
      saveFile(opts, sequenceDataToSave, editorState, onSuccessCallback) {
        if (this.readOnly) return;

        blobToBase64(opts.pngFile).then((base64image) => {
          (this.fileUrl ? axios.patch : axios.post)(
            this.updateUrl,
            {
              sequence_data: sequenceDataToSave,
              sequence_name: this.sequenceName || this.i18n.t('open_vector_editor.default_sequence_name'),
              base64_image: base64image
            }
          ).then(() => {
            parent.document.getElementById('iFrameModal').dispatchEvent(new Event('sequenceSaved'));
            if (this.closeAfterSave) this.closeModal();
          });
        });
      },
      closeModal() {
        if (parent !== window) {
          parent.document.getElementById('iFrameModal').dispatchEvent(new Event('hide'));
        }
      }
    }
  }
 </script>
