<template>
  <div ref="modal" class="modal fade" tabindex="-1" role="dialog">
    <div class="modal-dialog modal-sm" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close"><i class="sn-icon sn-icon-close"></i></button>
          <h4 class="modal-title">
            {{ i18n.t('repositories.item_card.relationships.unlink_modal.title') }}
          </h4>
        </div>
        <div class="modal-body">
          <p>{{ i18n.t('repositories.item_card.relationships.unlink_modal.description') }}</p>
        </div>
        <div class="modal-footer">
          <button class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.cancel') }}</button>
          <button class="btn btn-primary" data-dismiss="modal" @click="$emit('confirmed')">{{ i18n.t('repositories.item_card.relationships.unlink_modal.unlink') }}</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import modalMixin from '../shared/modal_mixin';

export default {
  name: 'UnlinkModal',
  mixins: [modalMixin],
  emits: ['confirmed', 'close']
};
</script>
