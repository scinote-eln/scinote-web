<template>
  <div ref="modal" @keydown.esc="cancel" class="modal" id="modalDestroyProtocolContent" tabindex="-1" role="dialog" data-e2e="e2e-MD-deleteStepResultElement">
    <div class="modal-dialog modal-sm" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close" data-e2e="e2e-BT-deleteStepResultElementModal-close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title" id="modal-delete-result-element" data-e2e="e2e-TX-deleteStepResultElementModal-title">
            {{ i18n.t('protocols.steps.modals.delete_element.title')}}
          </h4>
        </div>
        <div class="modal-body" data-e2e="e2e-TX-deleteStepResultElementModal-description">
          <p>{{ i18n.t('protocols.steps.modals.delete_element.description_1')}}</p>
          <p><b>{{ i18n.t('protocols.steps.modals.delete_element.description_2')}}</b></p>

        </div>
        <div class="modal-footer">
          <button class="btn btn-secondary" @click="close" data-e2e="e2e-BT-deleteStepResultElementModal-cancel">
            {{ i18n.t('general.cancel') }}
          </button>
          <button class="btn btn-danger" @click="confirm" data-e2e="e2e-BT-deleteStepResultElementModal-confirm">
            {{ i18n.t('protocols.steps.modals.delete_element.confirm')}}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
import modalMixin from '../../modal_mixin';

export default {
  name: 'deleteElementModal',
  mixins: [modalMixin],
  methods: {
    confirm() {
      this.$emit('confirm');
      this.$nextTick(() => this.close);
    }
  }
};
</script>
