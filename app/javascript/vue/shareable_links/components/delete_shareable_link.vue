<template>
  <div ref="modal" class="modal centered-modal" id="modalDestroyShareableLink" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close"><i class="sn-icon sn-icon-close"></i></button>
          <h4 class="modal-title" id="modal-destroy-shareable-link">
            {{ i18n.t('shareable_links.destroy_modal.title')}}
          </h4>
        </div>
        <div class="modal-body">
          <p class="text-sm">{{ i18n.t('shareable_links.destroy_modal.description')}}</p>
        </div>
        <div class="modal-footer">
          <button class="btn btn-secondary" tabindex="0" @click="cancel">{{ i18n.t('general.cancel') }}</button>
          <button class="btn btn-danger" tabindex="0" @click="confirm">{{ i18n.t('shareable_links.destroy_modal.deactivate')}}</button>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
export default {
  name: 'deleteShareableLinkModal',
  mounted() {
    $(this.$refs.modal).modal('show');
    $(this.$refs.modal).on('hidden.bs.modal', () => {
      this.$emit('cancel');
    });
  },
  methods: {
    confirm() {
      this.$emit('confirm');
      $(this.$refs.modal).modal('hide');
    },
    cancel() {
      $(this.$refs.modal).modal('hide');
    }
  }
};
</script>
