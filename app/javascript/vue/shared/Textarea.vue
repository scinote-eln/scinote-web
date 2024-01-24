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
                  [className]: true,
                  'text-sn-dark-grey': value, 'text-sn-grey': !value
                }"
        @click="enableEdit">
    <span v-if="smartAnnotation"
          v-html="sa_value || noContentPlaceholder"
          class="[&>p]:mb-0"></span>
    <span v-else>{{ value || noContentPlaceholder }}</span>
  </div>
</template>

<script>
export default {
  name: 'Textarea',
  data() {
    return {
      value: '',
      editing: false
    };
  },
  props: {
    expandable: { type: Boolean, required: true },
    collapsed: { type: Boolean, required: true },
    initialValue: String,
    noContentPlaceholder: String,
    placeholder: String,
    decimals: { type: Number, default: 0 },
    isNumber: { type: Boolean, default: false },
    unEditableRef: { type: String, required: true },
    smartAnnotation: { type: Boolean, default: false },
    sa_value: { type: String },
    className: { type: String, default: false }
  },
  mounted() {
    this.value = this.initialValue;
    this.$nextTick(() => {
      this.toggleExpandableState();
    });
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
  computed: {
    canEdit() {
      return this.permissions?.can_manage && !this.inArchivedRepositoryRow;
    }
  },
  methods: {
    handleKeydown(event) {
      if (event.key === 'Enter') {
        event.preventDefault();
        this.$refs.textareaRef.blur();
      }
    },
    handleBlur() {
      if ($('.atwho-view:visible').length) return;

      if (this.smartAnnotation) {
        this.value = this.$refs.textareaRef.value.trim(); // Fix for smart annotation
      }
      this.editing = false;
      this.toggleExpandableState();
      this.$emit('update', this.value);
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
      if (e && $(e.target).hasClass('atwho-user-popover')) return;
      if (e && $(e.target).hasClass('sa-link')) return;
      if (e && $(e.target).parent().hasClass('atwho-inserted')) return;

      this.editing = true;
      this.$nextTick(() => {
        if (this.smartAnnotation) {
          SmartAnnotation.init($(this.$refs.textareaRef), false);
        }
      });
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
      const regexp = this.decimals === 0 ? /[^0-9]/g : /[^0-9.]/g;
      const decimalsRegex = new RegExp(`^\\d*(\\.\\d{0,${this.decimals}})?`);
      let { value } = this;
      value = value.replace(regexp, '');
      value = value.match(decimalsRegex)[0];
      this.value = value;
    }
  }
};
</script>
