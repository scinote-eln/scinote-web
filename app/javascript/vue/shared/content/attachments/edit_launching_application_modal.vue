<template>
  <div ref="modal" @keydown.esc="cancel" class="modal" role="dialog" aria-hidden="true" tabindex="-1">
    <div class="modal-dialog">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h2 class="modal-title">{{ i18n.t('assets.edit_launching_application_modal.title') }}</h2>
        </div>
        <div class="modal-body">
          <p v-html="i18n.t(
            'assets.edit_launching_application_modal.description',
            { file_name: fileName, application: application }
          )"></p>
        </div>
        <div class="modal-footer">
          <button type='button' class='btn btn-secondary' @click="cancel">
            {{ i18n.t('general.close') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
export default {
  name: 'editLaunchingApplicationModal',
  props: {
    fileName: String, application: String,
  },
  mounted() {
    $(this.$refs.modal).modal('show');
    $(this.$refs.modal).on('hidden.bs.modal', () => {
      this.$emit('cancel');
    });
  },
  methods: {
    cancel() {
      $(this.$refs.modal).modal('hide');
    },
  },
};
</script>
