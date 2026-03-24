/* global HelperModule i18n */

import axios from '../../../../../packs/custom_axios.js';

export default {
  methods: {
    updateViewMode(viewMode) {
      this.$emit('attachment:viewMode', this.attachment.id, viewMode);
    },
    deleteAttachment() {
      axios.delete(this.attachment.attributes.urls.delete)
        .then((response) => {
          this.$emit('attachment:delete');
          HelperModule.flashAlertMsg(response.data.flash, 'success');
        })
        .catch(() => {
          HelperModule.flashAlertMsg(this.i18n.t('general.no_permissions'), 'danger');
        });
    },
    restoreAttachment() {
      axios.post(this.attachment.attributes.urls.restore)
        .then((response) => {
          this.$emit('attachment:restore');
        })
        .catch(() => {
          HelperModule.flashAlertMsg(this.i18n.t('general.no_permissions'), 'danger');
        });
    },
    archiveAttachment() {
      axios.post(this.attachment.attributes.urls.archive)
        .then((response) => {
          this.$emit('attachment:archive');
        })
        .catch(() => {
          HelperModule.flashAlertMsg(this.i18n.t('general.no_permissions'), 'danger');
        });
    },
    reloadAttachments() {
      this.$emit('attachment:uploaded');
    }
  }
};
