<template>
  <div class="w-full relative flex">
    <template v-if="editing">
      <input type="text"
        v-if="singleLine"
        ref="input"
        class="inline-block leading-5 outline-none pl-0 border-0 border-solid border-y w-full border-t-transparent"
        :class="{
          'py-1': !singleLine,
          'inline-edit-placeholder text-sn-grey caret-black': isBlank,
          'border-b-sn-delete-red': error,
          'border-b-sn-science-blue': !error,
        }"
        v-model="newValue"
        @keydown="handleKeypress"
        @blur="handleBlur"
        @keyup.escape="cancelEdit"
        @focus="setCaretAtEnd"/>
      <textarea v-else
        ref="input"
        class="overflow-hidden leading-5 inline-block outline-none px-0 py-1 border-0 border-solid border-y w-full border-t-transparent mb-0.5"
        :class="{
          'inline-edit-placeholder text-sn-grey caret-black': isBlank,
          'border-sn-delete-red': error,
          'border-sn-science-blue': !error,
        }"
        :placeholder="placeholder"
        v-model="newValue"
        @keydown="handleKeypress"
        @blur="handleBlur"
        @keyup.escape="cancelEdit"
        @focus="setCaretAtEnd"/>
    </template>
    <div
      v-else
      ref="view"
      class="grid sci-cursor-edit leading-5 border-0 outline-none border-solid border-y border-transparent"
      :class="{ 'text-sn-grey font-normal': isBlank, 'whitespace-pre-line py-1': !singleLine }"
      @click="enableEdit($event)"
    >
      <span :class="{'truncate': singleLine }" v-if="smartAnnotation" v-html="sa_value || placeholder" ></span>
      <span :class="{'truncate': singleLine}" v-else>{{newValue || placeholder}}</span>
    </div>

    <div
      class="mt-2 whitespace-nowrap truncate text-xs font-normal absolute bottom-[-1rem] w-full"
      :title="editing && error ? error : timestamp"
      :class="{'text-sn-delete-red': editing && error}"
    >
      {{ editing && error ? error : timestamp }}
    </div>
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
      timestamp: { type: String},
      placeholder: { type: String },
      autofocus: { type: Boolean, default: false },
      saveOnEnter: { type: Boolean, default: true },
      allowNewLine: { type: Boolean, default: false },
      multilinePaste: { type: Boolean, default: false },
      smartAnnotation: { type: Boolean, default: false },
      editOnload: { type: Boolean, default: false },
      defaultValue: { type: String, default: '' },
      singleLine: { type: Boolean, default: true },
      preventLeavingUntilFilled: { type: Boolean, default: false }
    },
    data() {
      return {
        editing: false,
        dirty: false,
        newValue: '',
      }
    },
    mixins: [UtilsMixin],
    created() {
      this.newValue = this.value || '';
    },
    mounted() {
      this.handleAutofocus();
      if (this.editOnload) {
        this.enableEdit();
      }
    },
    watch: {
      value(newVal, oldVal) {
        if (newVal !== oldVal) {
          this.newValue = newVal
        }
      },
      editing() {
        this.refreshTexareaHeight()
      },
      newValue() {
        if (this.newValue.length === 0 && this.editing) {
          this.focus();
        }
        this.refreshTexareaHeight();
      },
      autofocus() {
        this.handleAutofocus();
      },
    },
    computed: {
      isBlank() {
        if (typeof this.newValue === 'string') {
          return this.newValue.trim().length === 0;
        }
        return true; // treat as blank for non-string values
      },
      isContentDefault() {
        return this.newValue === this.defaultValue;
      },
      error() {
        if (!this.allowBlank && this.isBlank) {
          if (this.preventLeavingUntilFilled) {
            this.addPreventFromLeaving(document.body);
          }

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

        this.removePreventFromLeaving(document.body);
        return false
      }
    },
    methods: {
      removePreventFromLeaving(domEl) {
        domEl.removeEventListener('click', this.preventClicks, true);
        domEl.removeEventListener('mousedown', this.preventClicks, true);
        domEl.removeEventListener('mouseup', this.preventClicks, true);
      },
      addPreventFromLeaving(domEl) {
        domEl.addEventListener('click', this.preventClicks, true);
        domEl.addEventListener('mousedown', this.preventClicks, true);
        domEl.addEventListener('mouseup', this.preventClicks, true);
      },
      preventClicks(event) {
        event.stopPropagation();
        event.preventDefault();
      },
      handleAutofocus() {
        if (this.autofocus || !this.placeholder && this.isBlank || this.editOnload && this.isBlank) {
          this.enableEdit();
          setTimeout(this.focus, 50);
        }
      },
      handleBlur() {
        if ($('.atwho-view:visible').length) return;
        this.$emit('blur');
        if (this.allowBlank || !this.isBlank) {
          this.$nextTick(this.update);
        } else if (this.isBlank) {
          this.newValue = this.value || '';
        }
        else {
          this.$emit('delete')
        }
      },
      focus() {
        this.$nextTick(() => {
          if (!this.$refs.input) return;
          this.$refs.input.focus();
        });
      },
      setCaretAtEnd() {
        if (this.isBlank || this.isContentDefault) return;

        const el = this.$refs.input;
        el.focus();
      },
      enableEdit(e) {
        if (e && $(e.target).hasClass('atwho-user-popover')) return;
        if (e && $(e.target).hasClass('sa-link')) return;
        if (e && $(e.target).parent().hasClass('atwho-inserted')) return;

        this.editing = true;
        this.$nextTick(() => {
          this.focus();
          this.$refs.input.value = this.newValue;

          // Select whole content if it is default
          if (this.isContentDefault) {
            let range = document.createRange();
            range.selectNodeContents(this.$refs.input);
            let selection = window.getSelection();
            selection.removeAllRanges();
            selection.addRange(range);
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
      handleInput(e) {
        this.dirty = true;

        const sel = document.getSelection();
        const offset = sel.anchorOffset;

        this.newValue = this.allowNewLine ? e.target.textContent : e.target.textContent.replace(/^[\n\r]+|[\n\r]+$/g, '');

        sel.collapse(sel.anchorNode, offset);
      },
      handleKeypress(e) {
        if (e.key == 'Escape') {
          this.cancelEdit();
        } else if (e.key == 'Enter' && this.saveOnEnter && e.shiftKey == false) {
          e.preventDefault()
          this.update(e.key);
        } else {
          if (!this.error) this.$emit('error-cleared');
          this.dirty = true;
        }
        this.$emit('keypress', e)
      },
      update(withKey = null) {
        this.refreshTexareaHeight();

        if (!this.dirty && !this.isBlank) {
          this.editing = false;
          return;
        }

        if(this.error) return;
        if(!this.$refs.input) return;
        this.newValue = this.$refs.input.value.trim() // Fix for smart annotation

        this.editing = false;
        this.$emit('editingDisabled');
        this.$emit('update', this.newValue, withKey);
      },
      refreshTexareaHeight() {
        if (this.editing && !this.singleLine) {
          this.$nextTick(() => {
            if (!this.$refs.input) return;
            this.$refs.input.style.height = this.$refs.input.scrollHeight / 2  + 'px';

            this.$refs.input.style.height = this.$refs.input.scrollHeight  + 'px';
          });
        }
      }
    }
  }
</script>
