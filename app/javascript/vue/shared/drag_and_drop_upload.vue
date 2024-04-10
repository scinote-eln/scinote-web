<template>
  <div
    ref="dragAndDropUpload"
    @drop.prevent="dropFile"
    @dragenter.prevent="dragEnter($event)"
    @dragleave.prevent="dragLeave($event)"
    @dragover.prevent
    class="flex h-full w-full p-6 rounded border border-sn-light-grey bg-sn-super-light-blue"
  >
  <div id="centered-content" class="flex flex-col gap-4 items-center h-fit w-fit m-auto">
    <!-- icon -->
    <i class="sn-icon sn-icon-import text-sn-dark-grey"></i>

    <!-- text section -->
    <div class="flex flex-col gap-1">
      <div class="text-sn-dark-grey">
        <span class="text-sn-science-blue hover:cursor-pointer" @click="handleImportClick">
          {{ i18n.t('repositories.import_records.dragAndDropUpload.importText.firstPart') }}
        </span> {{ i18n.t('repositories.import_records.dragAndDropUpload.importText.secondPart') }}
      </div>
      <div class="text-sn-grey">
        {{ supportingText }}
      </div>
    </div>
  </div>

  <!-- hidden input for importing via 'Import' click -->
  <input type="file" ref="fileInput" style="display: none" @change="handleFileSelect">
  </div>
</template>

<script>

export default {
  name: 'DragAndDropUpload',
  props: {
    supportingText: {
      type: String,
      required: true
    },
    supportedFormats: {
      type: Array,
      required: true,
      default: () => []
    }
  },
  emits: ['file:dropped', 'file:error'],
  data() {
    return {
      draggingFile: false,
      uploading: false
    };
  },
  methods: {
    validateFile(file) {
      // check if it's a single file
      if (file.length > 1) {
        const error = I18n.t('repositories.import_records.dragAndDropUpload.notSingleFileError');
        this.$emit('file:error', error);
        return false;
      }

      // check if it's a correct file type
      const fileExtension = file.name.split('.')[1];
      if (!this.supportedFormats.includes(fileExtension)) {
        const error = I18n.t('repositories.import_records.dragAndDropUpload.wrongFileTypeError');
        this.$emit('file:error', error);
        return false;
      }

      // check if file is not empty
      if (!file.size > 0) {
        const error = I18n.t('repositories.import_records.dragAndDropUpload.emptyFileError');
        this.$emit('file:error', error);
        return false;
      }

      // check if it's conforming to size limit
      if (file.size > GLOBAL_CONSTANTS.FILE_MAX_SIZE_MB * 1024 * 1024) {
        const error = `${I18n.t('repositories.import_records.dragAndDropUpload.fileTooLargeError')} ${GLOBAL_CONSTANTS.FILE_MAX_SIZE_MB}`;
        this.$emit('file:error', error);
        return false;
      }
      return true;
    },
    dragEnter(e) {
      // Detect if dragged element is a file
      // https://stackoverflow.com/a/8494918
      const dt = e.dataTransfer;
      if (dt.types && (dt.types.indexOf ? dt.types.indexOf('Files') !== -1 : dt.types.contains('Files'))) {
        this.draggingFile = true;
      }
    },
    dragLeave() {
      this.draggingFile = false;
    },
    dropFile(e) {
      if (e.dataTransfer && e.dataTransfer.files.length) {
        this.draggingFile = false;
        this.uploading = true;
        const droppedFile = e.dataTransfer.files[0];

        const fileIsValid = this.validateFile(droppedFile);

        // successful drop
        if (fileIsValid) {
          this.$emit('file:dropped', droppedFile);
          this.$emit('file:error:clear');
        }
      }
    },
    handleImportClick() {
      this.$refs.fileInput.click();
    },
    handleFileSelect(event) {
      const file = event.target.files[0];
      const fileIsValid = this.validateFile(file);

      if (fileIsValid) {
        this.$emit('file:dropped', file);
      }
    }
  }
};
</script>
