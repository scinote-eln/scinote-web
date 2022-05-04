<template>
  <div ref="modal" class="modal" id="modalDestroyProtocolContent" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
          <h4 class="modal-title" id="modal-destroy-team-label">
            {{ i18n.t('protocols.steps.modals.delete_component.title')}}
          </h4>
        </div>
        <div class="modal-body">
          <p>{{ i18n.t('protocols.steps.modals.delete_component.description_1')}}</p>
          <p><b>{{ i18n.t('protocols.steps.modals.delete_component.description_2')}}</b></p>

        </div>
        <div class="modal-footer">
          <button class="btn btn-secondary" @click="cancel">{{ i18n.t('general.cancel') }}</button>
          <button class="btn btn-danger" @click="confirm">{{ i18n.t('protocols.steps.modals.delete_component.confirm')}}</button>
        </div>
      </div>
    </div>
  </div>
</template>
 <script>
  export default {
    name: 'deleteComponentModal',
    mounted() {
      $(this.$refs.modal).modal('show');
    },
    methods: {
      confirm() {
        $(this.$refs.modal).modal('hide');
        this.$emit('confirm');
      },
      cancel() {
        $(this.$refs.modal).modal('hide');
        this.$emit('cancel');
      }
    }
  }
</script>
