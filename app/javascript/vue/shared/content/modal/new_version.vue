<template>
  <div ref="modal" class="modal tinymce-co-editing-ui" tabindex="-1" role="dialog" data-e2e="e2e-MD-textNewVersion">
    <!-- tinymce-co-editing-ui is TinyMCE's custom_ui_selector: focusing this modal doesn't blur (auto-save) the editor -->
    <div class="modal-dialog" role="document">
      <div v-if="!confirmingOverwrite" class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close" data-e2e="e2e-BT-textNewVersionModal-close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title" data-e2e="e2e-TX-textNewVersionModal-title">
            {{ title }}
          </h4>
          <div v-if="subtitle" class="modal-subtitle text-sn-dark-grey" data-e2e="e2e-TX-textNewVersionModal-subtitle">
            {{ subtitle }}
          </div>
        </div>
        <div class="modal-body">
          <div class="max-h-[60vh] overflow-y-auto">
            <div v-if="previewHtml" ref="preview" class="view-text-element" v-html="previewHtml"></div>
            <div v-else class="text-sn-grey">
              {{ i18n.t('protocols.steps.text.empty_text') }}
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" @click="hide" data-e2e="e2e-BT-textNewVersionModal-cancel">
            {{ i18n.t('general.cancel') }}
          </button>
          <button type="button" class="btn btn-primary" @click="startOverwrite" data-e2e="e2e-BT-textNewVersionModal-overwrite">
            {{ i18n.t('protocols.steps.text.new_version.overwrite') }}
          </button>
        </div>
      </div>
      <div v-else class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close" data-e2e="e2e-BT-textNewVersionModal-close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title" data-e2e="e2e-TX-textNewVersionModal-title">
            {{ i18n.t('protocols.steps.text.new_version.confirm_title') }}
          </h4>
        </div>
        <div class="modal-body">
          <p v-if="confirm_line_1">{{ confirm_line_1 }}</p>
          <p>{{ i18n.t('protocols.steps.text.new_version.confirm_line_2') }}</p>
          <p>{{ i18n.t('protocols.steps.text.new_version.confirm_line_3') }}</p>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" @click="hide" data-e2e="e2e-BT-textNewVersionModal-cancel">
            {{ i18n.t('general.cancel') }}
          </button>
          <button type="button" class="btn btn-danger" @click="confirmOverwrite" data-e2e="e2e-BT-textNewVersionModal-confirmOverwrite">
            {{ i18n.t('protocols.steps.text.new_version.overwrite') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
/* global Prism */
import modalMixin from '../../modal_mixin';

export default {
  name: 'NewVersionModal',
  mixins: [modalMixin],
  props: {
    latestVersion: {
      type: Object,
      default: null
    }
  },
  data() {
    return {
      confirmingOverwrite: false,
      overwriteDigest: null
    };
  },
  computed: {
    title() {
      const name = this.latestVersion?.name;
      return name
        ? this.i18n.t('protocols.steps.text.new_version.title', { name })
        : this.i18n.t('protocols.steps.text.new_version.title_unnamed');
    },
    subtitle() {
      const time = this.latestVersion?.last_modified_on;
      const user = this.latestVersion.last_modified_by;
      if (!time || !user) return null;
  
      return this.i18n.t('protocols.steps.text.new_version.subtitle', { user, time })
    },
    confirm_line_1() {
      const time = this.latestVersion?.last_modified_on;
      const user = this.latestVersion.last_modified_by;
      if (!time || !user) return null;

      return this.i18n.t('protocols.steps.text.new_version.confirm_line_1', { user, time })
    },
    previewHtml() {
      const textView = this.latestVersion?.text_view;
      return textView ? window.wrapTables(textView) : '';
    },
  },
  watch: {
    latestVersion() {
      this.highlightPreview();
    }
  },
  mounted() {
    this.highlightPreview();
  },
  methods: {
    startOverwrite() {
      this.overwriteDigest = this.latestVersion?.text_digest;
      this.confirmingOverwrite = true;
    },
    confirmOverwrite() {
      this.$emit('overwrite', this.overwriteDigest);
      this.hide();
    },
    hide() {
      $(this.$refs.modal).modal('hide');
    },
    highlightPreview() {
      this.$nextTick(() => {
        if (typeof Prism === 'undefined' || !this.$refs.preview) return;

        Prism.highlightAllUnder(this.$refs.preview);
      });
    }
  }
};
</script>
