/* global HelperModule i18n */

export default {
  methods: {
    updateViewMode(viewMode) {
      this.$emit('attachment:viewMode', this.attachment.id, viewMode);
    },
    deleteAttachment() {
      $.ajax({
        url: this.attachment.attributes.urls.delete,
        type: 'DELETE',
        dataType: 'json',
        success: (result) => {
          this.$emit('attachment:delete');
          HelperModule.flashAlertMsg(result.flash, 'success');
        },
        error: () => {
          HelperModule.flashAlertMsg(this.i18n.t('general.no_permissions'), 'danger');
        }
      });
    },
    reloadAttachments() {
      this.$emit('attachment:uploaded');
    }
  }
};
