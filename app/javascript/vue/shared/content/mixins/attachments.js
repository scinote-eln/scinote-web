/* global ActiveStorage GLOBAL_CONSTANTS Promise I18n */

import { markRaw } from 'vue';
import axios from '../../../../packs/custom_axios.js';
import consumer from '../../../../channels/consumer';

export default {
  data() {
    return {
      viewModeOrder: {
        inline: 0,
        thumbnail: 1,
        list: 2
      },
      assetSyncSubscriptions: {}
    };
  },
  computed: {
    attachmentsParent() {
      return this.step || this.result;
    },
    attachmentsParentName() {
      return this.step ? 'step' : 'result';
    },
    cantUploadFiles() {
      return false;
    },
    // A primitive, so the watcher only fires when the set of ids changes - not when
    // reloadAttachment replaces an object in the array.
    assetSyncIds() {
      return this.attachments
        .filter((attachment) => attachment?.id && attachment.attributes?.urls?.open_locally)
        .map((attachment) => String(attachment.id))
        .join(',');
    }
  },
  watch: {
    assetSyncIds() {
      this.syncAssetSubscriptions();
    }
  },
  mounted() {
    this.syncAssetSubscriptions();
  },
  beforeUnmount() {
    this.unsubscribeAllAssetSync();
  },
  methods: {
    dropFile(e) {
      if (this.cantUploadFiles) return;

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
      this.toggleCollapsedSection();
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
          this.toggleCollapsedSection();
        } else {
          HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
        }
      });
    },
    toggleCollapsedSection() {
      if (this.isCollapsed) {
        this.$refs.toggleElement.click();
      }
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
    },
    syncAssetSubscriptions() {
      const watchedIds = this.assetSyncIds ? this.assetSyncIds.split(',') : [];

      Object.keys(this.assetSyncSubscriptions)
        .filter((assetId) => !watchedIds.includes(assetId))
        .forEach((assetId) => this.unsubscribeAssetSync(assetId));

      watchedIds.forEach((assetId) => this.subscribeAssetSync(assetId));
    },
    subscribeAssetSync(assetId) {
      if (assetId in this.assetSyncSubscriptions) return;
      this.assetSyncSubscriptions[assetId] = null;

      // markRaw, because ActionCable forgets a subscription and would
      // never match its reactive proxy; so unsubscribing would silently do nothing.
      this.assetSyncSubscriptions[assetId] = markRaw(consumer.subscriptions.create(
        { channel: 'AssetSyncChannel', asset_id: assetId },
        {
          received: (data) => {
            const attachment = this.attachments.find((a) => String(a?.id) === assetId);

            if (!attachment || data.checksum === attachment.attributes.checksum) return;

            this.reloadAttachment(attachment.id);
          },
          rejected: () => this.unsubscribeAssetSync(assetId)
        }
      ));
    },
    unsubscribeAssetSync(assetId) {
      if (!(assetId in this.assetSyncSubscriptions)) return;

      const subscription = this.assetSyncSubscriptions[assetId];

      if (subscription) consumer.subscriptions.remove(subscription);

      delete this.assetSyncSubscriptions[assetId];
    },
    unsubscribeAllAssetSync() {
      Object.keys(this.assetSyncSubscriptions).forEach((assetId) => this.unsubscribeAssetSync(assetId));
    },
    reloadAttachment(attachmentId) {
      const index = this.attachments.findIndex(attachment => attachment?.id === attachmentId);
      if (index === -1) return;

      const attachmentUrl = this.attachments[index].attributes.urls.asset_show;
      if (!attachmentUrl) return;

      axios.get(attachmentUrl)
        .then((response) => {
          const updatedAttachment = response.data?.data;
          const updatedIndex = this.attachments.findIndex(attachment => attachment?.id === attachmentId);

          if (updatedAttachment && updatedIndex !== -1) {
            this.attachments[updatedIndex] = updatedAttachment;
          }
        })
        .catch((error) => {
          console.error('Failed to reload attachment:', error);
        });
    }
  }
};
