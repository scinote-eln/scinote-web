<template>
  <div ref="modal" @keydown.esc="cancel" class="modal delete-steps-modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content" data-e2e="e2e-MD-task-protocol-deleteAllSteps">
        <div class="modal-header">
          <button
            type="button"
            class="close"
            data-dismiss="modal"
            aria-label="Close"
            data-e2e="e2e-BT-task-protocol-deleteAllStepsModal-close"
          >
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title" data-e2e="e2e-TX-task-protocol-deleteAllStepsModal-title">
            {{ i18n.t('protocols.steps.modals.delete_steps.title')}}
          </h4>
        </div>
        <div class="modal-body">
          <p data-e2e="e2e-TX-task-protocol-deleteAllStepsModal-description">
            {{ i18n.t('protocols.steps.modals.delete_steps.description_1')}}
          </p>
          <p class="warning" data-e2e="e2e-TX-task-protocol-deleteAllStepsModal-warning">
            {{ i18n.t('protocols.steps.modals.delete_steps.description_2')}}
          </p>
        </div>
        <div class="modal-footer">
          <button
            class="btn btn-secondary"
            @click="cancel"
            data-e2e="e2e-BT-task-protocol-deleteAllStepsModal-cancel"
          >
            {{ i18n.t('general.cancel') }}
          </button>
          <button
            class="btn btn-danger"
            @click="confirm"
            data-e2e="e2e-BT-task-protocol-deleteAllStepsModal-delete"
          >
            {{ i18n.t('protocols.steps.modals.delete_steps.confirm')}}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
export default {
  name: 'deleteStepsModal',
  mounted() {
    // move modal to body to avoid z-index issues
    $('body').append($(this.$refs.modal));

    $(this.$refs.modal).modal('show');
    $(this.$refs.modal).on('hidden.bs.modal', () => {
      this.$emit('close');
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
