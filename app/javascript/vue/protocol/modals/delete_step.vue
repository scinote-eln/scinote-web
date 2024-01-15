<template>
  <div ref="modal" @keydown.esc="cancel" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog modal-sm" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close"><i class="sn-icon sn-icon-close"></i></button>
          <h4 class="modal-title">
            {{ i18n.t('protocols.steps.modals.delete_step.title')}}
          </h4>
        </div>
        <div class="modal-body">
          <p>{{ i18n.t('protocols.steps.modals.delete_step.description_1')}}</p>
          <p><b>{{ i18n.t('protocols.steps.modals.delete_step.description_2')}}</b></p>

        </div>
        <div class="modal-footer">
          <button class="btn btn-secondary" @click="cancel">{{ i18n.t('general.cancel') }}</button>
          <button class="btn btn-danger" @click="confirm">{{ i18n.t('protocols.steps.modals.delete_step.confirm')}}</button>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
export default {
  name: 'deleteStepModal',
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
