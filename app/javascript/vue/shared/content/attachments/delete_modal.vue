<template>
  <div ref="modal" @keydown.esc="cancel" class="modal" role="dialog" aria-hidden="true" tabindex="-1">
    <div class="modal-dialog">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h2 class="modal-title">{{ i18n.t('assets.delete_file_modal.title') }}</h2>
        </div>
        <div class="modal-body">
          <p v-html="i18n.t('assets.delete_file_modal.description_1_html', { file_name: fileName })"></p>
          <p>{{ i18n.t('assets.delete_file_modal.description_2') }}</p>
        </div>
        <div class="modal-footer">
          <button type='button' class='btn btn-secondary' @click="cancel">
            {{ i18n.t('general.cancel') }}
          </button>
          <button type='button' class='btn btn-danger' @click="confirm">
            {{ i18n.t('assets.delete_file_modal.confirm_button') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
export default {
  name: 'deleteAttachmentModal',
  props: {
    fileName: String
  },
  mounted() {
    $(this.$refs.modal).modal('show');
    $(this.$refs.modal).on('hidden.bs.modal', () => {
      this.$emit('cancel');
    });
  },
  methods: {
    confirm() {
      $(this.$refs.modal).modal('hide');
      this.$emit('confirm');
    },
    cancel() {
      $(this.$refs.modal).modal('hide');
    }
  }
};
</script>
