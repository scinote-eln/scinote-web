<template>
  <div class="ove-wrapper flex flex-col h-screen">
    <div class="ove-header flex justify-between">
      <span class="file-name flex items-center ml-3">
        <div class="sci-input-container">
          <input v-model="sequenceName" class="sci-input-field" type="text" />
        </div>
      </span>
      <div class="ove-buttons">
        <button @click="saveAndClose" class="btn btn-light">
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
      updateUrl: { type: String }
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
      this.editor = window.createVectorEditor(this.$refs.container, {
        onSave: this.saveFile,
        generatePng: true
      });
      this.sequenceName = this.fileName || this.i18n.t('open_vector_editor.default_sequence_name');

      if (this.fileUrl) {
        this.loadFile();
      } else {
        this.editor.updateEditor(
          {
            sequenceData: { circular: true, name: this.sequenceName },
            readOnly: false
          }
        );
      }
    },
    methods: {
      loadFile() {
        fetch(this.fileUrl).then((response) => response.json()).then(
          (json) => this.editor.updateEditor(
            {
              sequenceData: json,
              readOnly: false
            }
          )
        );
      },
      saveAndClose() {
        this.closeAfterSave = close;
        document.querySelector('[data-test=saveTool]').click();
      },
      saveFile(opts, sequenceDataToSave, editorState, onSuccessCallback) {
        blobToBase64(opts.pngFile).then((base64image) => {
          (this.fileUrl ? axios.patch : axios.post)(
            this.updateUrl,
            {
              sequence_data: sequenceDataToSave,
              sequence_name: this.sequenceName,
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
