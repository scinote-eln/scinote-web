<template>
  <div>
    <div class="tinymce-container" :class="{ 'error': error }">
      <form class="tiny-mce-editor" role="form" :action="updateUrl" accept-charset="UTF-8" data-remote="true" method="post">
        <input type="hidden" name="_method" value="patch">
        <div class="hidden tinymce-cancel-button mce-widget mce-btn mce-menubtn mce-flow-layout-item mce-btn-has-text pull-right" tabindex="-1">
          <button type="button" tabindex="-1">
            <span class="fas fa-times"></span>
            <span class="mce-txt">{{ i18n.t('general.cancel')  }}</span>
          </button>
        </div>
        <div class="hidden tinymce-save-button mce-widget mce-btn mce-menubtn mce-flow-layout-item mce-btn-has-text mce-last pull-right" tabindex="-1">
          <button type="button" tabindex="-1">
            <span class="fas fa-check"></span>
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
        <div class="form-group">
          <textarea :id="`${objectType}_textarea_${objectId}`"
                    class="form-control hidden"
                    :placeholder="placeholder"
                    autocomplete="off"
                    :data-tinymce-object="`tinymce-${objectType}-description-${objectId}`"
                    :data-object-type="objectType"
                    :data-object-id="objectId"
                    :data-highlightjs-path="this.getStaticUrl('highlightjs-url')"
                    :data-last-updated="lastUpdated * 1000"
                    :data-tinymce-asset-path="this.getStaticUrl('tiny-mce-assets-url')"
                    :value="value"
                    cols="120"
                    rows="10"
                    :name="fieldName"
                    aria-hidden="true">
          </textarea>
          <input type="hidden" id="tiny-mce-images" name="tiny_mce_images" value="[]">
        </div>
      </form>
    </div>
    <div v-if="error" class="tinymce-error">
      {{ error }}
    </div>
  </div>
</template>

<script>
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
      characterLimit: {
        type: Number,
        default: null
      }
    },
    data() {
      return {
        editorInstance: null,
        characterCount: 0,
        blurEventHandler: null
      }
    },
    watch: {
      inEditMode() {
        if (this.inEditMode) {
          this.initTinymce()
        }
      },
      characterCount() {
        if(this.error) {
          this.editorInstance.blurDisabled = true;
        } else {
          this.editorInstance.blurDisabled = false;
        }
      }
    },
    computed: {
      error() {
        if(this.characterLimit && this.characterCount > this.characterLimit) {
          return(
            this.i18n.t(
              'inline_edit.errors.over_limit',
              { attribute: this.i18n.t('general.text.name'), limit: this.characterLimit }
            )
          )
        }

        return false
      }
    },
    methods: {
      initTinymce() {
        let textArea = `#${this.objectType}_textarea_${this.objectId}`;
        TinyMCE.init(textArea, (data) => {
          if (data) {
            this.$emit('update', data)
          }
          this.$emit('editingDisabled')
        }).then((editorInstance) => {
          this.editorInstance = editorInstance[0]; // TinyMCE initialization returns an array
          this.initCharacterCount();
        });
        this.$emit('editingEnabled')
      },
      getStaticUrl(name) {
        return $(`meta[name=\'${name}\']`).attr('content');
      },
      initCharacterCount() {
        this.characterCount = $(this.editorInstance.getContent()).text().length

        this.editorInstance.on('input', (e) => {
          this.characterCount = e.currentTarget.innerText.length
        });

        // clear error on cancel
        $(this.editorInstance.container).find('.tinymce-cancel-button').on('click', ()=> {
          this.characterCount = 0;
        });
      }
    }
  }
</script>
