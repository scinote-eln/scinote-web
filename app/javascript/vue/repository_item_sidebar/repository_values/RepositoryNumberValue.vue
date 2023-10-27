<template>
  <div id="repository-number-value-wrapper"
       class="flex flex-col min-h-[46px] h-auto gap-[6px]">
    <div class="font-inter text-sm font-semibold leading-5 flex justify-between">
      <div class="truncate" :class="{ 'w-4/5': expandable }" :title="colName">{{ colName }}</div>
      <div @click="toggleCollapse"
           v-show="expandable"
           class="font-normal leading-5 btn-text-link">
        {{
          collapsed
            ? i18n.t("repositories.item_card.repository_number_value.expand")
            : i18n.t("repositories.item_card.repository_number_value.collapse")
        }}
      </div>
    </div>
      <div v-if="canEdit">
        <textarea v-if="editing"
                  ref="textareaRef"
                  class="leading-5 inline-block outline-none border-solid font-normal border-[1px] box-content
                        overflow-x-hidden overflow-y-auto resize-none rounded px-4 py-2 w-[calc(100%-2rem)]"
                  :class="{
                    'border-sn-delete-red': error,
                    'border-sn-science-blue': !error,
                    'max-h-[4rem]': collapsed,
                    'max-h-[40rem]': !collapsed
                  }"
                  :placeholder="i18n.t('repositories.item_card.repository_number_value.placeholder')"
                  v-model="numberValue"
                  @keydown="handleKeydown"
                  @blur="handleBlur" />
        <div v-else
             ref="numberRef"
             class="grid box-content sci-cursor-edit font-normal border-solid px-4 py-2 border-sn-light-grey rounded
                    leading-5 border outline-none hover:border-sn-sleepy-grey overflow-y-auto whitespace-pre-line
                    w-[calc(100%-2rem)]"
             :class="{ 'max-h-[4rem]': collapsed,
                       'max-h-[40rem]': !collapsed, }"
             @click="enableEdit">
          <span v-html="numberValue || noContentPlaceholder" ></span>
        </div>
      </div>
      <div v-else-if="colVal"
           ref="numberRef"
           class="text-sn-dark-grey box-content font-inter text-sm font-normal leading-5 min-h-[20px] overflow-y-auto"
           :class="{
             'max-h-[4rem]': collapsed,
             'max-h-[40rem]': !collapsed
           }">
        {{ colVal }}
      </div>
      <div v-else
           class="text-sn-dark-grey font-inter text-sm font-normal leading-5">
        {{ i18n.t("repositories.item_card.repository_number_value.no_number") }}
      </div>
  </div>
</template>

<script>
import repositoryValueMixin from "./mixins/repository_value.js";

export default {
  name: "RepositoryNumberValue",
  mixins: [repositoryValueMixin],
  data() {
    return {
      expandable: false,
      collapsed: true,
      numberValue: '',
    };
  },
  props: {
    data_type: String,
    colId: Number,
    colName: String,
    colVal: String,
    permissions: null,
    inArchivedRepositoryRow: Boolean,
  },
  created() {
    // constants
    this.noContentPlaceholder = this.i18n.t("repositories.item_card.repository_number_value.no_number");
    this.decimals = Number(document.getElementById(`${this.colId}`).dataset['metadataDecimals']) || 0;
  },
  mounted() {
    this.numberValue = this.colVal;
    this.$nextTick(() => {
      this.toggleExpandableState();
    });
  },
  beforeUpdate() {
    if (!this.$refs.textareaRef) return;

    this.validateInput();
  },
  watch: {
    colVal: {
      handler() {
        this.numberValue = this.colVal;
        this.toggleExpandableState();
      },
      deep: true,
    },
    editing() {
      this.$nextTick(() => {
        if (this.editing) {
          this.setCaretAtEnd();
          this.refreshTextareaHeight();
          return;
        }

        this.toggleExpandableState();
      })
    }
  },
  computed: {
    canEdit() {
      return this.permissions?.can_manage && !this.inArchivedRepositoryRow;
    }
  },
  methods: {
    toggleCollapse() {
      if (this.expandable) {
        this.collapsed = !this.collapsed;
      }
    },
    handleKeydown(event) {
      if (event.key === 'Enter') {
        event.preventDefault();
        this.$refs.textareaRef.blur();
      }
    },
    handleBlur() {
      this.editing = false;
      this.toggleExpandableState();
      this.update(this.numberValue);
    },
    toggleExpandableState() {
      this.$nextTick(() => {
        if (!this.$refs.textRef) return;

        const maxCollapsedHeight = '96';
        const scrollHeight = this.$refs.textRef.scrollHeight;
        this.expandable = scrollHeight > maxCollapsedHeight;
      });
    },
    enableEdit(e) {
      if (e && $(e.target).hasClass('atwho-user-popover')) return;
      if (e && $(e.target).hasClass('sa-link')) return;
      if (e && $(e.target).parent().hasClass('atwho-inserted')) return;

      this.editing = true;
    },
    refreshTextareaHeight() {
      this.$nextTick(() => {
        if (!this.editing) return;
        const textarea = this.$refs.textareaRef;
        textarea.style.height = '0px';
        // 16px is the height of the textarea's line
        textarea.style.height = textarea.scrollHeight - 16 + 'px';
      });
    },
    setCaretAtEnd() {
      this.$nextTick(() => {
        if (!this.editing) return;

        this.$refs.textareaRef.focus();
      });
    },
    validateInput() {
      const regexp = this.decimals === 0 ? /[^0-9]/g : /[^0-9.]/g;
      const decimalsRegex = new RegExp(`^\\d*(\\.\\d{0,${this.decimals}})?`);
      let value = this.numberValue;
      value = value.replace(regexp, '');
      value = value.match(decimalsRegex)[0];
      this.numberValue = value;
    }
  },
};
</script>
