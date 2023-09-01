<template>
  <div class="flex flex-col">
    <span
      v-if="editing"
      ref="input"
      contenteditable="true"
      class="outline-none p-0 pb-2 border-0 border-solid border-b w-fit"
      :class="{ 'inline-edit-placeholder text-sn-grey caret-black': isBlank, 'border-sn-delete-red': error, 'border-sn-science-blue': !error }"
      :placeholder="placeholder"
      @input="handleInput"
      @keydown="handleKeypress"
      @paste="handlePaste"
      @blur="handleBlur"
      @keyup.escape="cancelEdit"
      @focus="setCaretAtEnd"
    ></span>
    <div 
      v-else-if="smartAnnotation"
      class="sci-cursor-edit"
      :class="{ 'blank': isBlank }"
      v-html="sa_value || placeholder"
      @click="enableEdit($event)"
    ></div>
    <div 
      v-else
      class="sci-cursor-edit outline-none"
      :class="{ 'text-sn-grey': isBlank }"
      @click="enableEdit($event)"
    >
      {{newValue || placeholder}}
    </div>
    
    <div 
      class="mt-2 whitespace-nowrap text-xs font-normal"
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
      newValue() {
        if (this.newValue.length === 0 && this.editing) {
          this.focus();
          this.setCaretPosition();
        }
      },
      autofocus() {
        this.handleAutofocus();
      }
    },
    computed: {
      isBlank() {
        return this.newValue.length === 0
      },
      isContentDefault() {
        return this.$refs ? this.$refs.input.innerText === this.defaultValue : false;
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
        });
      },
      // Fixing Firefox specific caret placement issue
      setCaretPosition() {
        const range = document.createRange();
        const sel = window.getSelection();
        range.setStart(this.$refs.input, 0);
        range.collapse(true);
        sel.removeAllRanges();
        sel.addRange(range);
      },
      setCaretAtEnd() {
        if (this.isBlank || this.isContentDefault) return;

        const el = this.$refs.input;
        let range = document.createRange();
        range.selectNodeContents(el);
        range.collapse(false);

        let selection = window.getSelection();
        selection.removeAllRanges();
        selection.addRange(range);
      },
      enableEdit(e) {
        if (e && $(e.target).hasClass('atwho-user-popover')) return;
        if (e && $(e.target).hasClass('sa-link')) return;
        if (e && $(e.target).parent().hasClass('atwho-inserted')) return;

        this.editing = true;
        this.$nextTick(() => {
          this.focus();
          this.$refs.input.innerText = this.newValue;

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
      handlePaste(e) {
        e.preventDefault();
        this.dirty = true;

        const clipboardData = (e.clipboardData || window.clipboardData).getData("text");
        let lines = clipboardData.split(/[\n\r]/).filter((l) => l).map((l) => l.trim());
        
        const selection = window.getSelection();
        if (!selection.rangeCount) return;

        selection.deleteFromDocument();

        let textNode = document.createTextNode(lines[0]);
        selection.getRangeAt(0).insertNode(textNode);

        let range = document.createRange();
        range.setStart(textNode, textNode.length);
        range.setEnd(textNode, textNode.length);

        this.$nextTick(() => {
          this.newValue = e.target.textContent;
          selection.removeAllRanges();
          selection.addRange(range);
          
          // Handle multi-line paste
          if (this.multilinePaste && lines.length > 1) {
            this.$emit('multilinePaste', lines);
            this.update();
          }
        });
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
        } else if (e.key == 'Enter' && this.saveOnEnter) {
          e.preventDefault()
          this.update();
        } else {
          if (!this.error) this.$emit('error-cleared');
          this.dirty = true;
        }
      },
      update() {
        if (!this.dirty && !this.isBlank) {
          this.editing = false;
          return;
        }

        if(this.error) return;
        if(!this.$refs.input) return;

        this.newValue = this.$refs.input.innerText.trim() // Fix for smart annotation
        this.editing = false;
        this.$emit('editingDisabled');
        this.$emit('update', this.newValue);
      }
    }
  }
</script>
