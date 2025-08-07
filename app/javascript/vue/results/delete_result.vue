<template>
  <div ref="modal" @keydown.esc="cancel" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog modal-sm" role="document">
      <div class="modal-content" data-e2e="e2e-MD-task-result-deleteResult">
        <div class="modal-header">
          <button
            type="button"
            class="close"
            data-dismiss="modal"
            aria-label="Close"
            data-e2e="e2e-BT-task-result-deleteResultModal-close"
          >
            <i class="sn-icon sn-icon-close">
          </i></button>
          <h4 class="modal-title" data-e2e="e2e-TX-task-result-deleteResultModal-title">
            {{ i18n.t("my_modules.results.delete_modal.title") }}
          </h4>
        </div>
        <div class="modal-body" data-e2e="e2e-TX-task-result-deleteResultModal-description">
          <p>{{ i18n.t("my_modules.results.delete_modal.description_1") }}</p>
          <p><b>{{ i18n.t("my_modules.results.delete_modal.description_2") }}</b></p>

        </div>
        <div class="modal-footer">
          <button
            class="btn btn-secondary"
            @click="cancel"
            data-e2e="e2e-BT-task-result-deleteResultModal-cancel"
          >
            {{ i18n.t('general.cancel') }}
          </button>
          <button
            class="btn btn-danger"
            @click="confirm"
            data-e2e="e2e-BT-task-result-deleteResultModal-delete"
          >
            {{ i18n.t("my_modules.results.delete_modal.confirm") }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
export default {
  name: 'deleteResultModal',
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
