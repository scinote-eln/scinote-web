/* global ActiveStorage GLOBAL_CONSTANTS Promise I18n */

export default {
  data() {
    return {
      viewModeOrder: {
        inline: 0,
        thumbnail: 1,
        list: 2
      }
    };
  },
  methods: {
    dropFile(e) {
      if (!this.showFileModal && e.dataTransfer && e.dataTransfer.files.length) {
        this.dragingFile = false;
        this.uploadFiles(e.dataTransfer.files);
      }
    },
    uploadFiles(files) {
      const filesToUploadCntr = files.length;
      let filesUploadedCntr = 0;
      this.showFileModal = false;

      return new Promise((resolve, reject) => {
        $(files).each((_, file) => {
          const fileObject = {
            attributes: {
              progress: 0,
              view_mode: this.step.attributes.assets_view_mode,
              file_name: file.name,
              uploading: true,
              asset_order: this.viewModeOrder[this.step.attributes.assets_view_mode]
            },
            directUploadWillStoreFileWithXHR(request) {
              request.upload.addEventListener('progress', (e) => {
                // Progress checking
                this.attributes.progress = parseInt((e.loaded / e.total) * 100, 10);
              });
            }
          };
          if (file.size > GLOBAL_CONSTANTS.FILE_MAX_SIZE_MB * 1024 * 1024) {
            fileObject.error = I18n.t('protocols.steps.attachments.new.file_too_big');
            this.attachments.push(fileObject);
            return;
          }

          const upload = new ActiveStorage.DirectUpload(file, this.step.attributes.urls.direct_upload_url, fileObject);

          fileObject.isNewUpload = true;
          this.attachments.push(fileObject);

          upload.create((error, blob) => {
            if (error) {
              fileObject.error = I18n.t('protocols.steps.attachments.new.general_error');
              reject(error);
            } else {
              const signedId = blob.signed_id;
              $.post(this.step.attributes.urls.upload_attachment_url, {
                signed_blob_id: signedId
              }, (result) => {
                fileObject.id = result.data.id;
                fileObject.attributes = result.data.attributes;
              });
              filesUploadedCntr += 1;
              if (filesUploadedCntr === filesToUploadCntr) {
                this.$emit('stepUpdated');
                resolve('done');
              }
            }
          });
        });
      });
    },
    changeAttachmentsOrder(order) {
      this.step.attributes.assets_order = order;
      $.post(this.step.attributes.urls.update_view_state_step_url, {
        assets: { order }
      });
    },
    changeAttachmentsViewMode(viewMode) {
      this.step.attributes.assets_view_mode = viewMode;
      this.attachments.forEach((attachment) => {
        this.$set(attachment.attributes, 'view_mode', viewMode);
        this.$set(attachment.attributes, 'asset_order', this.viewModeOrder[viewMode]);
      });
      $.post(this.step.attributes.urls.update_asset_view_mode_url, {
        assets_view_mode: viewMode
      });
    },
    updateAttachmentViewMode(id, viewMode) {
      const attachment = this.attachments.find(e => e.id === id);
      this.$set(attachment.attributes, 'view_mode', viewMode);
      this.$set(attachment.attributes, 'asset_order', this.viewModeOrder[viewMode]);
    }
  }
};
