/* global ActiveStorage GLOBAL_CONSTANTS Promise */

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
    directUploadWillStoreFileWithXHR(request) {
      request.upload.addEventListener('progress', () => {
        // Progress checking
      });
    },
    uploadFiles(files) {
      const filesToUploadCntr = files.length;
      let filesUploadedCntr = 0;
      this.showFileModal = false;

      return new Promise((resolve, reject) => {
        $(files).each((_, file) => {
          if (file.size > GLOBAL_CONSTANTS.FILE_MAX_SIZE_MB * 1024 * 1024) {
            // Handle large file size
            return;
          }

          const upload = new ActiveStorage.DirectUpload(file, this.step.attributes.urls.direct_upload_url, this);

          upload.create((error, blob) => {
            if (error) {
              reject(error);
            } else {
              const signedId = blob.signed_id;
              $.post(this.step.attributes.urls.upload_attachment_url, {
                signed_blob_id: signedId
              }, (result) => {
                this.attachments.push(result.data);
              });
              filesUploadedCntr += 1;
              if (filesUploadedCntr === filesToUploadCntr) {
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
