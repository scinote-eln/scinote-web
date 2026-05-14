<template>
  <div ref="modal" @keydown.esc="cancel" class="modal archive-steps-modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content" data-e2e="e2e-MD-task-protocol-archiveAllSteps">
        <div class="modal-header">
          <button
            type="button"
            class="close"
            data-dismiss="modal"
            aria-label="Close"
            data-e2e="e2e-BT-task-protocol-archiveAllStepsModal-close"
          >
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title" data-e2e="e2e-TX-task-protocol-archiveAllStepsModal-title">
            {{ i18n.t('protocols.steps.modals.archive_steps.title')}}
          </h4>
        </div>
        <div class="modal-body">
          <p data-e2e="e2e-TX-task-protocol-archiveAllStepsModal-description">
            {{ i18n.t('protocols.steps.modals.archive_steps.description_1')}}
          </p>
          <p class="warning" data-e2e="e2e-TX-task-protocol-archiveAllStepsModal-warning">
            {{ i18n.t('protocols.steps.modals.archive_steps.description_2')}}
          </p>
        </div>
        <div class="modal-footer">
          <button
            class="btn btn-secondary"
            @click="cancel"
            data-e2e="e2e-BT-task-protocol-archiveAllStepsModal-cancel"
          >
            {{ i18n.t('general.cancel') }}
          </button>
          <button
            class="btn btn-danger"
            @click="confirm"
            data-e2e="e2e-BT-task-protocol-archiveAllStepsModal-archive"
          >
            {{ i18n.t('protocols.steps.modals.archive_steps.confirm')}}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
import modalMixin from '../../shared/modal_mixin.js';

export default {
  name: 'ArchiveStepsModal',
  mixins: [modalMixin],
  methods: {
    confirm() {
      this.$emit('confirm');
      this.close();
    }
  }
};
</script>
