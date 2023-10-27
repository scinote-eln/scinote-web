<template>
  <div id="repository-text-value-wrapper"
       class="flex flex-col min-h-[46px] h-auto gap-[6px]">
    <div class="font-inter text-sm font-semibold leading-5 flex justify-between">
      <div class="truncate" :class="{ 'w-4/5': expandable }" :title="colName">{{ colName }}</div>
      <div @click="toggleCollapse"
           v-show="expandable"
           class="font-normal leading-5 btn-text-link">
        {{
          collapsed
            ? i18n.t("repositories.item_card.repository_text_value.expand")
            : i18n.t("repositories.item_card.repository_text_value.collapse")
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
                :placeholder="i18n.t('repositories.item_card.repository_text_value.placeholder')"
                v-model="textValue"
                @keydown="handleKeydown"
                @blur="handleBlur" />
      <div v-else
            ref="textRef"
            class="grid box-content sci-cursor-edit font-normal border-solid px-4 py-2 border-sn-light-grey rounded
                   leading-5 border outline-none hover:border-sn-sleepy-grey overflow-y-auto whitespace-pre-line
                   w-[calc(100%-2rem)]"
            :class="{ 'max-h-[4rem]': collapsed,
                      'max-h-[40rem]': !collapsed, }"
            @click="enableEdit">
        <span v-html="textValue || noContentPlaceholder" ></span>
      </div>
    </div>
    <div v-else-if="colVal?.edit"
          ref="textRef"
          class="text-sn-dark-grey box-content text-sm font-normal leading-5 overflow-y-auto px-4 py-2
              border-sn-light-grey border border-solid rounded w-[calc(100%-2rem)]]"
          :class="{
            'max-h-[4rem]': collapsed,
            'max-h-[40rem]': !collapsed
          }"
    >
      {{ colVal?.edit }}
    </div>
    <div v-else class="text-sn-dark-grey font-inter text-sm font-normal leading-5 px-4 py-2 w-[calc(100%-2rem)]]">
      {{ i18n.t("repositories.item_card.repository_text_value.no_text") }}
    </div>
  </div>
</template>

<script>
import repositoryValueMixin from "./mixins/repository_value.js";

export default {
  name: "RepositoryTextValue",
  mixins: [repositoryValueMixin],
  data() {
    return {
      expandable: false,
      collapsed: true,
      textValue: '',
    };
  },
  props: {
    data_type: String,
    colId: Number,
    colName: String,
    colVal: Object,
    permissions: null,
    inArchivedRepositoryRow: Boolean,
  },
  created() {
    // constants
    this.noContentPlaceholder = this.i18n.t("repositories.item_card.repository_text_value.no_text");
  },
  mounted() {
    this.textValue = this.colVal?.edit;
    this.$nextTick(() => {
      if (this.$refs.textRef) {
        const textHeight = this.$refs.textRef.scrollHeight
        this.expandable = textHeight > 60 // 60px
      }
      this.toggleExpandableState();
    });
  },
  watch: {
    colVal: {
      handler() {
        this.textValue = this.colVal?.edit;
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
      this.refreshTextareaHeight();
    },
    handleBlur() {
      this.editing = false;
      this.toggleExpandableState();
      this.update(this.textValue);
    },
    toggleExpandableState() {
      this.$nextTick(() => {
        if (!this.$refs.textRef) return;

        const maxCollapsedHeight = '96';
        const scrollHeight = this.$refs.textRef.scrollHeight;
        this.expandable = scrollHeight > maxCollapsedHeight;
      });
    },
    enableEdit() {
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
    }
  },
};
</script>
