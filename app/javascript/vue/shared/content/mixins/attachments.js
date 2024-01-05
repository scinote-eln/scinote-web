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
  computed: {
    attachmentsParent() {
      return this.step || this.result;
    },
    attachmentsParentName() {
      return this.step ? 'step' : 'result';
    }
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
      MarvinJsEditor.initNewButton('.new-marvinjs-upload-button', this.loadAttachments);
      button.click();
    },
    openWopiFileModal() {
      this.initWopiFileModal(this.attachmentsParent, (_e, attachmentData, status) => {
        if (status === 'success') {
          const attachment = attachmentData.data;
          this.addAttachment(attachment);
        } else {
          HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
        }
      });
    },
    addAttachment(attachment) {
      this.attachments.push(attachment);
      this.showFileModal = false;
    },
    uploadFiles(files) {
      const filesToUploadCntr = files.length;
      let filesUploadedCntr = 0;
      this.showFileModal = false;

      if (!this.attachmentsParent.attributes.urls.upload_attachment_url) return false;

      return new Promise((resolve, reject) => {
        $(files).each((_, file) => {
          const fileObject = {
            attributes: {
              progress: 0,
              view_mode: this.attachmentsParent.attributes.assets_view_mode,
              file_name: file.name,
              uploading: true,
              asset_order: this.viewModeOrder[this.attachmentsParent.attributes.assets_view_mode]
            },
            directUploadWillStoreFileWithXHR(request) {
              request.upload.addEventListener('progress', (e) => {
                // Progress checking
                this.attributes.progress = parseInt((e.loaded / e.total) * 100, 10);
              });
            }
          };
          if (file.size > GLOBAL_CONSTANTS.FILE_MAX_SIZE_MB * 1024 * 1024) {
            fileObject.error = I18n.t('attachments.new.file_too_big');
            this.attachments.push(fileObject);
            return;
          }

          const storageLimit = this.attachmentsParent.attributes.storage_limit &&
                               this.attachmentsParent.attributes.storage_limit.total > 0 &&
                               this.attachmentsParent.attributes.storage_limit.used >= this.attachmentsParent.attributes.storage_limit.total;
          if (storageLimit) {
            fileObject.error = I18n.t('attachments.new.no_more_space');
            this.attachments.push(fileObject);
            return;
          }

          const upload = new ActiveStorage.DirectUpload(file, this.attachmentsParent.attributes.urls.direct_upload_url, fileObject);

          fileObject.isNewUpload = true;
          this.attachments.push(fileObject);
          const filePosition = this.attachments.length - 1;

          upload.create((error, blob) => {
            if (error) {
              fileObject.error = I18n.t('attachments.new.general_error');
              this.attachments = this.attachments.with(filePosition, fileObject);
              reject(error);
            } else {
              const signedId = blob.signed_id;
              $.post(this.attachmentsParent.attributes.urls.upload_attachment_url, {
                signed_blob_id: signedId
              }, (result) => {
                fileObject.id = result.data.id;
                fileObject.attributes = result.data.attributes;
                this.attachments = this.attachments.with(filePosition, fileObject);
              }).fail(() => {
                fileObject.error = I18n.t('attachments.new.general_error');
                this.attachments = this.attachments.with(filePosition, fileObject);
              });
              filesUploadedCntr += 1;
              if (filesUploadedCntr === filesToUploadCntr) {
                setTimeout(() => {
                  this.$emit(`${this.attachmentsParentName}Updated`);
                }, 1000);
                resolve('done');
              }
            }
          });
        });
      });
    },
    changeAttachmentsOrder(order) {
      this.attachmentsParent.attributes.assets_order = order;
      $.post(this.attachmentsParent.attributes.urls.update_view_state_url, {
        assets: { order }
      });
    },
    changeAttachmentsViewMode(viewMode) {
      this.attachmentsParent.attributes.assets_view_mode = viewMode;
      this.attachments.forEach((attachment) => {
        attachment.attributes['view_mode'] = viewMode;
        attachment.attributes['asset_order'] = this.viewModeOrder[viewMode];
      });
      $.post(this.attachmentsParent.attributes.urls.update_asset_view_mode_url, {
        assets_view_mode: viewMode
      });
    },
    updateAttachmentViewMode(id, viewMode) {
      const attachment = this.attachments.find(e => e.id === id);
      attachment.attributes['view_mode'] = viewMode;
      attachment.attributes['asset_order'] = this.viewModeOrder[viewMode];
    }
  }
};
