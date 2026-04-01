<template>
  <div ref="modal" @keydown.esc="cancel" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close"><i class="sn-icon sn-icon-close"></i></button>
          <h4 class="modal-title">
            {{ i18n.t('my_modules.results.modals.restore.title')}}
          </h4>
        </div>
        <div class="modal-body flex flex-col gap-6">
          <p>{{ i18n.t('my_modules.results.modals.restore.description_1')}}</p>
          <p>{{ i18n.t('my_modules.results.modals.restore.description_2')}}</p>

        </div>
        <div class="modal-footer">
          <button class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.cancel') }}</button>
          <button class="btn btn-primary" @click="this.$emit('confirm')">{{ i18n.t('my_modules.results.modals.restore.confirm')}}</button>
        </div>
      </div>
    </div>
  </div>
</template>
<script>

import modalMixin from '../../shared/modal_mixin.js';

export default {
  name: 'restoreResultModal',
  mixins: [modalMixin]
};
</script>
