<template>
  <div ref="modal" @keydown.esc="close" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close"><i class="sn-icon sn-icon-close"></i></button>
          <h4 class="modal-title">
            {{ i18n.t('scinote.native_tables.import_error_modal_title') }}
          </h4>
        </div>
        <div class="modal-body"> {{ i18n.t('scinote.native_tables.import_error_modal_description') }}</div>
        <div class="modal-footer">
          <button type="button" class="btn btn-primary" data-dismiss="modal">{{ i18n.t('general.close') }}</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>

import modalMixin from '../modal_mixin';

export default {
  name: 'TableImportErrorModal',
  mixins: [modalMixin]
};
</script>
