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
    openLoadFromComputer() {
      this.$refs.fileSelector.click();
    },
    loadFromComputer() {
      this.uploadFiles(this.$refs.fileSelector.files);
    },
    openMarvinJsModal(button) {
      MarvinJsEditor.initNewButton('.new-marvinjs-upload-button', () => {
        this.loadAttachments
      });
      button.click();
    },
    openWopiFileModal() {
      this.initWopiFileModal(this.step, (_e, data, status) => {
        if (status === 'success') {
          this.addAttachment(data)
        } else {
          HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
        }
      });
    },
    uploadFiles(files) {
      const filesToUploadCntr = files.length;
      let filesUploadedCntr = 0;
      this.showFileModal = false;

      if (!this.step.attributes.urls.upload_attachment_url) return false;

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

          const storageLimit = this.step.attributes.storage_limit &&
                               this.step.attributes.storage_limit.total > 0 &&
                               this.step.attributes.storage_limit.used >= this.step.attributes.storage_limit.total;
          if (storageLimit) {
            fileObject.error = I18n.t('protocols.steps.attachments.new.no_more_space');
            this.attachments.push(fileObject);
            return;
          }

          const upload = new ActiveStorage.DirectUpload(file, this.step.attributes.urls.direct_upload_url, fileObject);

          fileObject.isNewUpload = true;
          this.attachments.push(fileObject);
          const filePosition = this.attachments.length - 1;

          upload.create((error, blob) => {
            if (error) {
              fileObject.error = I18n.t('protocols.steps.attachments.new.general_error');
              this.attachments.splice(filePosition, 1);
              setTimeout(() => {
                this.attachments.push(fileObject);
              }, 0);
              reject(error);
            } else {
              const signedId = blob.signed_id;
              $.post(this.step.attributes.urls.upload_attachment_url, {
                signed_blob_id: signedId
              }, (result) => {
                fileObject.id = result.data.id;
                fileObject.attributes = result.data.attributes;
              }).fail(() => {
                fileObject.error = I18n.t('protocols.steps.attachments.new.general_error');
                this.attachments.splice(filePosition, 1);
                setTimeout(() => {
                  this.attachments.push(fileObject);
                }, 0);
              });
              filesUploadedCntr += 1;
              if (filesUploadedCntr === filesToUploadCntr) {
                setTimeout(() => {
                  this.$emit('stepUpdated');
                }, 1000);
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
