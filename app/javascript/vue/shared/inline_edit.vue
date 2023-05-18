<template>
  <div class="sci-inline-edit" :class="{ 'editing': editing }" tabindex="0" @keyup.enter="enableEdit($event)">
    <div class="sci-inline-edit__content" :class="{ 'error': error }">
      <textarea
        ref="input"
        rows="1"
        v-if="editing"
        :placeholder="placeholder"
        v-model="newValue"
        @input="handleInput"
        @keydown="handleKeypress"
        @paste="handlePaste"
        @blur="handleBlur"
        @keyup.escape="cancelEdit"
      ></textarea>
      <div v-else-if="smartAnnotation" @click="enableEdit($event)" class="sci-inline-edit__view" v-html="sa_value || placeholder" :class="{ 'blank': isBlank }"></div>
      <div v-else @click="enableEdit($event)" class="sci-inline-edit__view" :class="{ 'blank': isBlank }">{{newValue || placeholder}}</div>
      <div v-if="editing && error" class="sci-inline-edit__error">
        {{ error }}
      </div>
    </div>
    <template v-if="editing">
      <div :class="{ 'btn-primary': !error, 'btn-disabled': error }" class="sci-inline-edit__control btn icon-btn" @click="update">
        <i class="fas fa-check"></i>
      </div>
      <div class="sci-inline-edit__control btn btn-light icon-btn" @mousedown="cancelEdit">
        <i class="fas fa-times"></i>
      </div>
    </template>
  </div>
</template>

<script>
  import UtilsMixin from '../mixins/utils.js';

  export default {
    name: 'InlineEdit',
    props: {
      value: { type: String, default: '' },
      sa_value: { type: String},
      allowBlank: { type: Boolean, default: true },
      attributeName: { type: String, required: true },
      characterLimit: { type: Number },
      characterMinLimit: { type: Number },
      placeholder: { type: String },
      autofocus: { type: Boolean, default: false },
      saveOnEnter: { type: Boolean, default: true },
      allowNewLine: { type: Boolean, default: false },
      multilinePaste: { type: Boolean, default: false },
      smartAnnotation: { type: Boolean, default: false },
      editOnload: { type: Boolean, default: false },
      defaultValue: { type: String, default: '' }
    },
    data() {
      return {
        editing: false,
        dirty: false,
        newValue: ''
      }
    },
    mixins: [UtilsMixin],
    created( ){
      this.newValue = this.value || '';
    },
    mounted() {
      this.handleAutofocus();
      if (this.editOnload) {
        this.enableEdit();
      }
    },
    watch: {
      autofocus() {
        this.handleAutofocus();
      },
      value() {
        this.newValue = this.value;
      }
    },
    computed: {
      isBlank() {
        return this.newValue.length === 0
      },
      error() {
        if(!this.allowBlank && this.isBlank) {
          return this.i18n.t('inline_edit.errors.blank', { attribute: this.attributeName })
        }
        if(this.characterLimit && this.newValue.length > this.characterLimit) {
          return(
            this.i18n.t('inline_edit.errors.over_limit',
              {
                attribute: this.attributeName,
                limit: this.numberWithSpaces(this.characterLimit)
              }
            )
          )
        }
        if (this.characterMinLimit && this.newValue.length < this.characterMinLimit) {
          return (
            this.i18n.t('inline_edit.errors.below_limit',
              {
                attribute: this.attributeName,
                limit: this.numberWithSpaces(this.characterMinLimit)
              }
            )
          )
        }

        return false
      }
    },
    methods: {
      handleAutofocus() {
        if (this.autofocus || !this.placeholder && this.isBlank || this.editOnload && this.isBlank) {
          this.enableEdit();
          setTimeout(this.focus, 50);
        }
      },
      handleBlur() {
        if ($('.atwho-view:visible').length) return;

        if (this.allowBlank || !this.isBlank) {
          this.$nextTick(this.update);
        } else {
          this.$emit('delete');
        }
      },
      focus() {
        this.$nextTick(() => {
          if (!this.$refs.input) return;

          this.$refs.input.focus();
          this.resize();
        });
      },
      enableEdit(e) {
        if (e && $(e.target).hasClass('atwho-user-popover')) return;
        if (e && $(e.target).hasClass('sa-link')) return;
        if (e && $(e.target).parent().hasClass('atwho-inserted')) return;

        this.editing = true;
        this.focus();
        this.$nextTick(() => {
          if (this.$refs.input.value === this.defaultValue) {
            this.$refs.input.select();
          }
          if (this.smartAnnotation) {
            SmartAnnotation.init($(this.$refs.input), false);
          }
        })
        this.$emit('editingEnabled');
      },
      cancelEdit() {
        this.editing = false;
        this.newValue = this.value || '';
        this.$emit('editingDisabled');
      },
      handlePaste(e) {
        this.dirty = true;

        if (!this.multilinePaste) return;
        let lines = (e.originalEvent || e).clipboardData.getData('text/plain').split(/[\n\r]/);
        lines = lines.filter((l) => l).map((l) => l.trim());

        if (lines.length > 1) {
          this.newValue = lines[0];
          this.$emit('multilinePaste', lines);
          this.update();
        }
      },
      handleInput() {
        this.dirty = true;
        if (!this.allowNewLine) {
          this.newValue = this.newValue.replace(/^[\n\r]+|[\n\r]+$/g, '');
        }
        this.$nextTick(this.resize);
      },
      handleKeypress(e) {
        if (e.key == 'Escape') {
          this.cancelEdit();
        } else if (e.key == 'Enter' && this.saveOnEnter) {
          this.update();
        } else {
          this.dirty = true;
        }
      },
      resize() {
        if (!this.$refs.input) return;

        this.$refs.input.style.height = "auto";
        this.$refs.input.style.height = (this.$refs.input.scrollHeight) + "px";
      },
      update() {
        if (!this.dirty && !this.isBlank) {
          this.editing = false;
          return;
        }

        if(this.error) return;
        if(!this.$refs.input) return;
        this.newValue = this.$refs.input.value // Fix for smart annotation
        this.newValue = this.newValue.trim();
        this.editing = false;
        this.$emit('editingDisabled');
        this.$emit('update', this.newValue);
      }
    }
  }
</script>
