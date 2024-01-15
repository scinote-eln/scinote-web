<template>
  <div class="tinymce-wrapper">
    <div class="tinymce-container" :class="{ 'error': error }">
      <form class="tiny-mce-editor" role="form" :action="updateUrl" accept-charset="UTF-8" data-remote="true" method="post">
        <input type="hidden" name="_method" value="patch">
        <div class="hidden tinymce-cancel-button tox-mbtn" tabindex="-1">
        <button type="button" tabindex="-1">
          <span class="sn-icon sn-icon-close"></span>
          <span class="mce-txt">{{ i18n.t('general.cancel') }}</span>
        </button>
        </div>
        <div class="hidden tinymce-save-button tox-mbtn" tabindex="-1">
          <button type="button" tabindex="-1" >
            <span class="sn-icon sn-icon-check"></span>
            <span class="mce-txt">{{ i18n.t('general.save') }}</span>
          </button>
        </div>
        <div class="hidden tinymce-status-badge pull-right">
          <i class="fas fa-check-circle"></i>
          <span>{{ i18n.t('tiny_mce.saved_label') }}</span>
        </div>

        <div :id="`${objectType}_view_${objectId}`"
            @click="initTinymce"
            v-html="value_html"
            class="ql-editor tinymce-view"
            :data-placeholder="placeholder"
            :data-tinymce-init="`tinymce-${objectType}-description-${objectId}`">
        </div>
        <div class="flex tinymce-editor-container">
          <textarea :id="`${objectType}_textarea_${objectId}`"
                    class="form-control hidden"
                    autocomplete="off"
                    :data-tinymce-object="`tinymce-${objectType}-description-${objectId}`"
                    :data-object-type="objectType"
                    :data-object-id="objectId"
                    :data-last-updated="lastUpdated * 1000"
                    :data-tinymce-asset-path="this.getStaticUrl('tiny-mce-assets-url')"
                    :placeholder="placeholder"
                    :value="value"
                    cols="120"
                    rows="10"
                    :name="fieldName"
                    aria-hidden="true">
          </textarea>
          <input type="hidden" class="tiny-mce-images" name="tiny_mce_images" value="[]">
        </div>
      </form>
    </div>
    <div v-if="active && error" class="tinymce-error">
      {{ error }}
    </div>
  </div>
</template>

<script>
import UtilsMixin from '../mixins/utils.js';

export default {
  name: 'Tinymce',
  props: {
    value: String,
    value_html: String,
    placeholder: String,
    updateUrl: String,
    objectType: String,
    objectId: Number,
    fieldName: String,
    lastUpdated: Number,
    inEditMode: Boolean,
    assignableMyModuleId: Number,
    characterLimit: {
      type: Number,
      default: null
    }
  },
  data() {
    return {
      characterCount: 0,
      blurEventHandler: null,
      active: false
    };
  },
  mixins: [UtilsMixin],
  watch: {
    inEditMode() {
      if (this.inEditMode) {
        this.initTinymce();
      } else {
        this.wrapTables();
      }

      this.initCodeHighlight();
    },
    characterCount() {
      if (this.editorInstance()) {
        this.editorInstance().blurDisabled = this.error != false;
      }
    }
  },
  computed: {
    error() {
      if (this.characterLimit && this.characterCount > this.characterLimit) {
        return (
          this.i18n.t('errors.general_text_too_long')
        );
      }

      return false;
    }
  },
  mounted() {
    if (this.inEditMode) {
      this.initTinymce();
    } else {
      this.wrapTables();
    }

    this.initCodeHighlight();
  },
  methods: {
    initTinymce(e) {
      const textArea = `#${this.objectType}_textarea_${this.objectId}`;

      if (this.active) return;
      if (e && $(e.target).prop('tagName') === 'A') return;
      if (e && $(e.target).hasClass('atwho-user-popover')) return;
      if (e && $(e.target).hasClass('record-info-link')) return;
      if (e && $(e.target).parent().hasClass('record-info-link')) return;
      if (e && $(e.target).parent().hasClass('atwho-inserted')) return;

      TinyMCE.init(textArea, {
        onSaveCallback: (data) => {
          if (data.data) {
            this.$emit('update', data.data);
          }
          this.$emit('editingDisabled');
          this.wrapTables();
          this.initCodeHighlight();
        },
        afterInitCallback: () => {
          this.active = true;
          this.initCharacterCount();
          this.$emit('editingEnabled');
        },
        placeholder: this.placeholder,
        assignableMyModuleId: this.assignableMyModuleId
      });
    },
    getStaticUrl(name) {
      return $(`meta[name=\'${name}\']`).attr('content');
    },
    wrapTables() {
      this.$nextTick(() => {
        TinyMCE.wrapTables($(this.$el).find('.tinymce-view'));
      });
    },
    initCharacterCount() {
      if (!this.editorInstance()) return;

      this.characterCount = this.editorInstance().plugins.wordcount.body.getCharacterCount();
      this.editorInstance().on('input change paste keydown', (e) => {
        e.currentTarget && (this.characterCount = this.editorInstance().plugins.wordcount.body.getCharacterCount());
      });

      this.editorInstance().on('remove', () => this.active = false);

      // clear error on cancel
      $(this.editorInstance().container).find('.tinymce-cancel-button').on('click', () => {
        this.characterCount = 0;
      });
    },
    editorInstance() {
      return tinyMCE.activeEditor;
    },
    initCodeHighlight() {
      this.$nextTick(() => {
        Prism.highlightAllUnder(this.$el);
      });
    }
  }
};
</script>
