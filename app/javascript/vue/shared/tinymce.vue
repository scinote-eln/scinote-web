<template>
  <div class="tinymce-wrapper">
    <div class="tinymce-container" :class="{ 'error': error }">
      <form class="tiny-mce-editor" role="form" :action="updateUrl" accept-charset="UTF-8" data-remote="true" method="post">
        <input type="hidden" name="_method" value="patch">
        <input type="hidden" name="format" value="json">
        <input type="hidden" name="output" value="object">
        <input v-if="textDigest" type="hidden" name="base_text_digest" :value="submitDigest">
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
        <div class="flex w-full tinymce-editor-container">
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
    <Teleport v-if="editorHeader && newVersionAvailable" :to="editorHeader">
      <div class="tinymce-new-version-banner col-span-full flex items-center gap-3 !px-4 !py-2 !text-sm
                  !bg-sn-background-brittlebush !border-0 !border-b !border-solid !border-sn-alert-brittlebush"
           data-e2e="e2e-CO-tinymce-newVersionBanner"
           @mousedown.prevent>
        <i class="sn-icon sn-icon-alert-warning !text-sn-alert-brittlebush"></i>
        <span class="grow">{{ i18n.t('protocols.steps.text.new_version.banner') }}</span>
        <button type="button"
                class="btn btn-secondary btn-sm !border !border-solid !cursor-pointer !whitespace-nowrap"
                data-e2e="e2e-BT-tinymce-newVersion-seeLatest"
                @click="$emit('showLatestVersion')">
          {{ i18n.t('protocols.steps.text.new_version.see_latest') }}
        </button>
      </div>
    </Teleport>
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
    textDigest: {
      type: String,
      default: null
    },
    newVersionAvailable: {
      type: Boolean,
      default: false
    },
    characterLimit: {
      type: Number,
      default: null
    },
    editingFlags: {
      type: Array,
      default: () => []
    }
  },
  data() {
    return {
      characterCount: 0,
      blurEventHandler: null,
      active: false,
      saving: false,
      initializing: false,
      baseDigest: null,
      submitDigest: null,
      editorHeader: null
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
    newVersionAvailable() {
      this.refreshStickyHeader();
    },
    editorHeader() {
      if (this.newVersionAvailable) this.refreshStickyHeader();
    },
    characterCount() {
      if (this.editorInstance()) {
        this.editorInstance().blurDisabled = this.error != false;
      }
    },
    editingFlags() {
      this.toggleEditingIndicator();
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
    $(this.$el).find('form.tiny-mce-editor')
      .on('ajax:send.coEditing', () => { this.saving = true; })
      .on('ajax:complete.coEditing', (_ev, xhr) => {
        this.saving = false;
        if (xhr.status !== 200 && xhr.status !== 409) this.$emit('saveFailed');
      });

    if (this.inEditMode) {
      this.initTinymce();
    } else {
      this.wrapTables();
    }

    this.initCodeHighlight();
  },
  beforeUnmount() {
    $(this.$el).find('form.tiny-mce-editor').off('.coEditing');
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

      this.initializing = true;
      this.baseDigest = this.textDigest;
      this.submitDigest = this.textDigest;

      TinyMCE.init(textArea, {
        onSaveCallback: (data) => {
          if (data.data) {
            this.$emit('update', data.data);
          }
          this.$emit('editingDisabled');
          this.wrapTables();
          this.initCodeHighlight();
        },
        onConflictCallback: this.textDigest ? (json) => { this.$emit('conflict', json); } : null,
        afterInitCallback: () => {
          this.active = true;
          this.initializing = false;
          this.initEditorHeader();
          this.initCharacterCount();
          this.toggleEditingIndicator();
          this.$emit('editingEnabled');
        },
        onInput: () => {
          this.$emit('input');
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
    initEditorHeader() {
      const editor = this.editorInstance();
      if (!editor) return;

      this.editorHeader = editor.getContainer()?.querySelector('.tox-editor-header') || null;
      editor.on('remove', () => {
        this.editorHeader = null;
        this.initializing = false;
      });
    },
    refreshStickyHeader() {
      this.$nextTick(() => {
        const editor = this.editorInstance();
        if (editor && this.editorHeader) {
          editor.dispatch('ResizeEditor');
          editor.execCommand('mceAutoResize');
        }
      });
    },
    overwrite(digest) {
      this.submitDigest = digest;
      this.$nextTick(() => {
        const editor = this.editorInstance();
        if (editor) TinyMCE.save(editor);
      });
    },
    focusEditor() {
      const editor = this.editorInstance();
      if (editor) editor.focus();
    },
    editorInstance() {
      // Not tinyMCE.activeEditor: that's a page-wide singleton that points at whichever editor
      // currently has focus, so a watcher reacting to *this* component's own props (e.g. a
      // remote editingFlags update while the user has since focused a different field) would
      // otherwise mutate a completely different editor's toolbar.
      return tinyMCE.get(`${this.objectType}_textarea_${this.objectId}`);
    },
    toggleEditingIndicator() {
      if (!this.editorInstance()) return;

      const container = $(this.editorInstance().container);
      const active = this.editingFlags.length > 0;

      container.toggleClass('editing-flags-active', active);

      const menubar = container.find('.tox-menubar');
      let tag = menubar.find('.editing-flags-tag');

      if (active && !tag.length) {
        // Inserted before the save/cancel controls (a normal flex sibling, not absolutely
        // positioned) so it can never overlap the menu items - at narrow widths it just sits
        // wherever flex layout puts it instead of overlapping "Insert"/"Format" etc.
        menubar.find('.tinymce-save-controls').before(`<div class="editing-flags-tag">${this.i18n.t('general.currently_being_edited')}</div>`);
      } else if (!active) {
        tag.remove();
      }
    },
    initCodeHighlight() {
      this.$nextTick(() => {
        if (typeof Prism === 'undefined') {
          setTimeout(() => {
            this.initCodeHighlight();
          }, 100);
          return;
        }
        Prism.highlightAllUnder(this.$el);
      });
    }
  }
};
</script>
