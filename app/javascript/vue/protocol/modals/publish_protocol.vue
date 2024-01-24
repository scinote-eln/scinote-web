<template>
  <div ref="modal" @keydown.esc="cancel" class="modal publish-modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close"><i class="sn-icon sn-icon-close"></i></button>
          <h4 class="modal-title">
            {{ i18n.t('protocols.publish_modal.title', { nr: protocol.attributes.version })}}
          </h4>
        </div>
        <div class="modal-body">
          <div class="sci-input-container">
            <label>{{ i18n.t('protocols.publish_modal.name')}}</label>
            <div>{{ protocol.attributes.name }}</div>
          </div>
          <div class="sci-input-container">
            <label>{{ i18n.t('protocols.publish_modal.comment')}}</label>
            <textarea ref="textarea"
                      v-model="protocol.attributes.version_comment"
                      class="sci-input-field"
                      :placeholder="i18n.t('protocols.publish_modal.comment_placeholder')">
            </textarea>
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn btn-secondary" @click="cancel">{{ i18n.t('general.cancel') }}</button>
          <button class="btn btn-primary" @click="confirm">{{ i18n.t('protocols.publish_modal.publish')}}</button>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
export default {
  name: 'publishProtocol',
  props: {
    protocol: {
      type: Object,
      required: true
    }
  },
  mounted() {
    $(this.$refs.modal).modal('show');
    $(this.$refs.modal).on('hidden.bs.modal', () => {
      this.$emit('cancel');
    });
    $(this.$refs.textarea).focus();
  },
  methods: {
    confirm() {
      $(this.$refs.modal).modal('hide');
      this.$emit('publish', this.protocol.attributes.version_comment);
    },
    cancel() {
      $(this.$refs.modal).modal('hide');
    }
  }
};
</script>
