<template>
  <div ref="modal" @keydown.esc="cancel" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close"><i class="sn-icon sn-icon-close"></i></button>
          <h4 class="modal-title">
            {{ i18n.t('protocols.steps.text.restore_modal.title')}}
          </h4>
        </div>
        <div class="modal-body flex flex-col gap-6">
          <p>{{ i18n.t(`protocols.steps.text.restore_modal.description_1_${parentType}`)}}</p>
          <p>{{ i18n.t('protocols.steps.text.restore_modal.description_2')}}</p>
        </div>
        <div class="modal-footer">
          <button class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.cancel') }}</button>
          <button class="btn btn-primary" @click="$emit('confirm')">{{ i18n.t('protocols.steps.text.restore_modal.confirm')}}</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import modalMixin from '../../modal_mixin.js';
export default {
  name: 'RestoreTableModal',
  mixins: [modalMixin],
  props: {
    parentType: {
      type: String,
      required: false
    }
  }
};
</script>
