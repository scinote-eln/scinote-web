<template>
  <textarea v-if="editing"
            ref="textareaRef"
            class="leading-5 inline-block outline-none border-solid font-normal border-[1px] box-content
                  overflow-x-hidden overflow-y-auto resize-none rounded py-2 w-[calc(100%-1.5rem)]
                  border-sn-science-blue"
            :class="{
              'max-h-[4rem]': collapsed,
              'max-h-[40rem]': !collapsed,
              [className]: true
            }"
            :placeholder="placeholder"
            v-model="value"
            @keydown="handleKeydown"
            @blur="handleBlur"></textarea>
  <div v-else
        :ref="unEditableRef"
        class="grid box-content sci-cursor-edit font-normal border-solid py-2 border-sn-light-grey rounded
              leading-5 border outline-none hover:border-sn-sleepy-grey overflow-y-auto whitespace-pre-line"
        :class="{ 'max-h-[4rem]': collapsed,
                  'max-h-[40rem]': !collapsed,
                  '!border-0 !pl-0': !canEdit,
                  [className]: true,
                  'text-sn-dark-grey': value, 'text-sn-grey': !value,
                  'focus-visible:border-sn-science-blue': canEdit
                }"
        :tabindex="canEdit ? 0 : null"
        @click="enableEdit"
        @focus="handleFocus">
    <span v-if="sanitizedValue" v-html="sanitizedValue"></span>
    <span v-else>{{ value || noContentPlaceholder }}</span>
  </div>
</template>

<script>
export default {
  name: 'Textarea',
  data() {
    return {
      value: '',
      editing: false,
      restoringFocus: false
    };
  },
  props: {
    expandable: { type: Boolean, required: true },
    collapsed: { type: Boolean, required: true },
    initialValue: String,
    sanitizedValue: { type: String, default: null },
    noContentPlaceholder: String,
    placeholder: String,
    canEdit: { type: Boolean, default: false },
    decimals: { type: Number, default: 0 },
    isNumber: { type: Boolean, default: false },
    unEditableRef: { type: String, required: true },
    smartAnnotation: { type: Boolean, default: false },
    className: { type: String, default: false }
  },
  mounted() {
    this.value = this.initialValue;
    this.$nextTick(() => {
      this.toggleExpandableState();
    });
    this.renderSmartAnnotations();
  },
  beforeUpdate() {
    if (!this.$refs.textareaRef) return;

    if (this.isNumber) this.enforceNumberInput();
  },
  watch: {
    initialValue: {
      handler() {
        this.value = this.initialValue || '';
        this.toggleExpandableState();
      },
      deep: true
    },
    value() {
      this.refreshTextareaHeight();
    },
    editing() {
      if (this.editing) {
        this.setCaretAtEnd();
        this.refreshTextareaHeight();
        return;
      }

      this.toggleExpandableState();
    }
  },
  methods: {
    handleKeydown(event) {
      if (event.key === 'Enter') {
        event.preventDefault();
        this.$refs.textareaRef.blur();
        this.restoreFocus();
      }
    },
    restoreFocus() {
      this.$nextTick(() => {
        // The textarea is removed once editing ends; give focus back to the view so Tab continues from here
        const view = this.$refs[this.unEditableRef];
        if (document.activeElement !== document.body || !view) return;

        this.restoringFocus = true;
        view.focus();
        this.restoringFocus = false;
      });
    },
    handleBlur() {
      if ($('.atwho-view:visible').length) return;

      if (this.smartAnnotation) {
        this.value = this.$refs.textareaRef.value.trim(); // Fix for smart annotation
      }
      const initialValue = this.smartAnnotation ? (this.initialValue || '').trim() : (this.initialValue || '');
      const changed = (this.value || '') !== initialValue;

      this.editing = false;
      this.toggleExpandableState();
      if (changed) this.$emit('update', this.value);
      this.renderSmartAnnotations();
    },
    toggleExpandableState() {
      this.$nextTick(() => {
        if (!this.$refs[this.unEditableRef]) return;

        const maxCollapsedHeight = '80';
        const { scrollHeight } = this.$refs[this.unEditableRef];
        const expandable = scrollHeight > maxCollapsedHeight;
        this.$emit('toggleExpandableState', expandable);
      });
    },
    enableEdit(e) {
      if (!this.canEdit) return;

      if (e && $(e.target).hasClass('atwho-user-popover')) return;
      if (e && $(e.target).hasClass('sa-name')) return;
      if (e && $(e.target).hasClass('sa-link')) return;
      if (e && $(e.target).parent().hasClass('atwho-inserted')) return;

      this.editing = true;
      this.$nextTick(() => {
        if (this.smartAnnotation) {
          SmartAnnotation.init($(this.$refs.textareaRef), false);
        }
      });
    },
    handleFocus(event) {
      if (this.editing || this.restoringFocus) return;
      // Only keyboard focus enters edit mode here. Mouse focus goes through @click, whose target guards
      // keep smart annotation links working (Safari focuses the view div instead of the link on mousedown).
      if (!event.target.matches(':focus-visible')) return;

      this.enableEdit();
    },
    refreshTextareaHeight() {
      this.$nextTick(() => {
        if (!this.editing) return;
        const textarea = this.$refs.textareaRef;
        textarea.style.height = '0px';
        // 16px is the height of the textarea's line
        textarea.style.height = `${textarea.scrollHeight - 16}px`;
      });
    },
    setCaretAtEnd() {
      this.$nextTick(() => {
        if (!this.editing) return;

        this.$refs.textareaRef.focus();
      });
    },
    enforceNumberInput() {
      const regexp = this.decimals === 0 ? /[^0-9-]/g : /[^0-9.-]/g;
      const decimalsRegex = new RegExp(`^-?\\d*(\\.\\d{0,${this.decimals}})?`);
      let { value } = this;
      value = value.replace(regexp, '');
      value = value.match(decimalsRegex)[0];
      this.value = value;
    },
    renderSmartAnnotations() {
      if (!this.smartAnnotation) return;

      this.$nextTick(() => {
        window.renderElementSmartAnnotations(
          this.$refs[this.unEditableRef],
          'span',
          document.querySelector('#repositoryItemSidebar #body-wrapper')
        );
      });
    }
  }
};
</script>
