<template>
  <div ref="modal" @keydown.esc="cancel" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document" :data-e2e="e2eAttributes.modalName">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close" :data-e2e="e2eAttributes.close"><i class="sn-icon sn-icon-close"></i></button>
          <h4 class="modal-title" :data-e2e="e2eAttributes.title">
            {{ title }}
          </h4>
        </div>
        <div class="modal-body" v-html="description"></div>
        <div class="modal-footer">
          <button :class="cancelClass" @click="cancel" :data-e2e="e2eAttributes.cancel">{{ cancelText || i18n.t('general.cancel') }}</button>
          <button :class="confirmClass" @click="confirm" :data-e2e="e2eAttributes.confirm">{{ confirmText || i18n.t('general.confirm') }}</button>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
export default {
  name: 'confirmationModal',
  props: {
    title: {
      type: String,
      required: true
    },
    description: {
      type: String,
      required: true
    },
    cancelText: {
      type: String
    },
    cancelClass: {
      type: String,
      default: 'btn btn-secondary'
    },
    confirmText: {
      type: String
    },
    confirmClass: {
      type: String,
      default: 'btn btn-primary'
    },
    e2eAttributes: {
      type: Object,
      default: () => ({})
    }
  },
  mounted() {
    $(this.$refs.modal).on('hidden.bs.modal', () => {
      this.resolvePromise(false);
    });
  },
  data() {
    return {
      resolvePromise: null,
      rejectPromise: null
    };
  },
  methods: {
    show() {
      $(this.$refs.modal).modal('show');
      return new Promise((resolve, reject) => {
        this.resolvePromise = resolve;
        this.rejectPromise = reject;
      });
    },
    confirm() {
      this.resolvePromise(true);
      $(this.$refs.modal).modal('hide');
    },
    cancel() {
      this.resolvePromise(false);
      $(this.$refs.modal).modal('hide');
    }
  }
};
</script>
