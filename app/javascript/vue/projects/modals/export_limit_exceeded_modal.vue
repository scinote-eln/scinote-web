<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title truncate !block" id="edit-project-modal-label">
            {{ i18n.t('repositories.index.modal_export_limit_exceeded.title') }}
          </h4>
        </div>
        <div class="modal-body" v-html="description"></div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.close') }}</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>

import modalMixin from '../../shared/modal_mixin';

export default {
  name: 'ExportLimitExceededModal',
  props: {
    description: {
      type: String,
      required: true
    }
  },
  mixins: [modalMixin]
};
</script>
