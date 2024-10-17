<template>
  <div ref="modal" @keydown.esc="cancel" class="modal" id="RestrictedExtensionModal" tabindex="-1" role="dialog">
    <div class="modal-dialog modal-md" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close"><i class="sn-icon sn-icon-close"></i></button>
          <h4 class="modal-title" id="modal-delete-result-element">
            {{ i18n.t('assets.restricted_extension_modal.title') }}
          </h4>
        </div>
        <div class="modal-body">
          <p v-html="i18n.t('assets.restricted_extension_modal.body')"></p>
        </div>
        <div class="modal-footer">
          <button class="btn btn-primary" @click="close">{{ this.i18n.t('assets.restricted_extension_modal.action') }}</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import modalMixin from '../../modal_mixin';

export default {
  name: 'RestrictedExtensionModal',
  mixins: [modalMixin]
};
</script>
