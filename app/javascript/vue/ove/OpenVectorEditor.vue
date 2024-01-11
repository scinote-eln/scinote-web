<template>
  <div class="ove-wrapper flex flex-col h-screen">
    <div class="ove-header flex justify-between h-14 px-4 py-2">
      <span class="file-name flex items-center ml-3 w-56">
        <div class="sci-input-container-v2 w-full">
          <input v-model="sequenceName"
                 class="sci-input-field"
                 type="text"
                 :disabled="readOnly"
                 :placeholder="i18n.t('open_vector_editor.sequence_name_placeholder')"/>
        </div>
      </span>
      <div v-if="oveWarning" class="flex items-center">
        <i class="mr-1 text-brand-warning sn-icon sn-icon-alert-warning"></i>
        <p v-html="oveWarning" class="mb-0"></p>
      </div>
      <div class="ove-buttons text-sn-blue">
        <button :style="{ pointerEvents: 'all' }" @click="saveAndClose" class="btn btn-light font-sans" :disabled="this.readOnly">
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
import { blobToBase64 } from '../shared/blobToBase64.js';

export default {
  name: 'OpenVectorEditor',
  props: {
    fileUrl: { type: String },
    fileName: { type: String },
    updateUrl: { type: String },
    canEditFile: { type: String },
    oveWarning: { type: String }
  },
  data() {
    return {
      editor: null,
      sequenceName: null,
      closeAfterSave: false,
      readOnly: this.canEditFile !== 'true'
    };
  },
  mounted() {
    let editorConfig = {
      onSave: this.saveFile,
      generatePng: true,
      showMenuBar: true,
      alwaysAllowSave: true,
      menuFilter: this.menuFilter,
      beforeReadOnlyChange: this.readOnlyHandler,
      showCircularity: true,
      ToolBarProps: {
        toolList: [
          'saveTool',
          'downloadTool',
          { name: 'importTool', tooltip: I18n.t('open_vector_editor.editor.tooltips.importTool'), disabled: this.readOnly },
          'undoTool',
          'redoTool',
          'cutsiteTool',
          'featureTool',
          'partTool',
          'oligoTool',
          'orfTool',
          // Hide allignment tool
          // 'alignmentTool',
          'editTool',
          'findTool',
          'visibilityTool'
        ]
      }
    };

    if (this.readOnly) {
      editorConfig = {
        ...editorConfig,
        showReadOnly: false,
        ToolBarProps: {
          toolList: []
        }
      };
    }

    this.editor = window.createVectorEditor(this.$refs.container, editorConfig);
    this.sequenceName = this.fileName;

    if (this.fileUrl) {
      this.loadFile();
    } else {
      this.editor.updateEditor(
        {
          sequenceData: { circular: true, name: this.sequenceName },
          readOnly: this.readOnly
        }
      );
    }
    this.$nextTick(this.attachEditorHelpCallback);
  },
  methods: {
    loadFile() {
      fetch(this.fileUrl).then((response) => response.json()).then(
        (json) => this.editor.updateEditor(
          { sequenceData: json, readOnly: this.readOnly }
        )
      );
    },
    saveAndClose() {
      this.closeAfterSave = true;
      document.querySelector('[data-test=saveTool]').click();
    },
    saveFile(opts, sequenceDataToSave) {
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
    },
    menuFilter(menus) {
      return menus.map((menu) => {
        if (menu.text !== 'Help') return menu;
        const menuOverride = {
          ...menu,
          submenu: menu.submenu.filter((item) => item.cmd !== 'versionNumber')
        };

        return menuOverride;
      });
    },
    readOnlyHandler(val) { this.readOnly = val; return true; },
    // override click event for github issue link in editor help -> about modal
    attachEditorHelpCallback() {
      $(window.document).on('click', '.bp3-dialog-container .bp3-dialog .bp3-alert-contents a', (event) => {
        event.preventDefault();
        $('.bp3-dialog .bp3-dialog-footer button[type*=submit]').trigger('click');
        window.open($(event.target).attr('href'), '_blank');
      });
    }
  }
};
</script>
