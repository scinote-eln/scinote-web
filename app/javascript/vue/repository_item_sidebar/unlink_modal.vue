<template>
  <div ref="modal" @keydown.esc="cancel" class="modal fade" tabindex="-1" role="dialog">
    <div class="modal-dialog modal-sm" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" @click="cancel" aria-label="Close"><i class="sn-icon sn-icon-close"></i></button>
          <h4 class="modal-title">
            {{ i18n.t('repositories.item_card.relationships.unlink_modal.title') }}
          </h4>
        </div>
        <div class="modal-body">
          <p>{{ i18n.t('repositories.item_card.relationships.unlink_modal.description') }}</p>
        </div>
        <div class="modal-footer">
          <button class="btn btn-secondary" @click="cancel">{{ i18n.t('general.cancel') }}</button>
          <button class="btn btn-primary" @click="confirm">{{ i18n.t('repositories.item_card.relationships.unlink_modal.unlink') }}</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'UnlinkModal',
  mounted() {
    $(this.$refs.modal).modal('show');
  },
  methods: {
    cancel() {
      this.hide(() => {
        this.$emit('cancel');
      });
    },
    confirm() {
      this.hide(() => {
        this.$emit('unlink');
      });
    },
    hide(callback) {
      $(this.$refs.modal).one('hidden.bs.modal', () => {
        callback();
      });
      $(this.$refs.modal).modal('hide');
    }
  }
};
</script>
