<template>
  <div ref="modal" @keydown.esc="cancel" class="modal" id="modalUpdateVersion" tabindex="-1" role="dialog">
    <div class="modal-dialog modal-md" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close"><i class="sn-icon sn-icon-close"></i></button>
          <h4 class="modal-title" id="modal-delete-result-element">
            {{ i18n.t('assets.update_version_modal.title') }}
          </h4>
        </div>
        <div class="modal-body">
          <p v-html="i18n.t('assets.update_version_modal.body_text_html')"></p>
        </div>
        <div class="modal-footer">
          <button class="btn btn-secondary" @click="close">{{ i18n.t('general.cancel') }}</button>
          <ScinoteEditDownload
            :data="userAgent"
            :isUpdateVersionModal="true"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import ScinoteEditDownload from '../../../../vue/shared/scinote_edit_download.vue';
import modalMixin from '../../modal_mixin';

export default {
  name: 'UpdateVersionModal',
  components: {
    ScinoteEditDownload
  },
  mixins: [modalMixin],
  props: {
    fileName: String
  },
  computed: {
    userAgent() {
      return window.navigator.userAgent;
    }
  }
};
</script>
