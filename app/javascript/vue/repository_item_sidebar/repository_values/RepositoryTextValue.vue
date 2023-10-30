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
    <div>
      <inline-edit
        v-if="permissions?.can_manage && !inArchivedRepositoryRow"
        ref="textRef"
        :value="colVal?.edit"
        :placeholder="i18n.t('repositories.item_card.repository_text_value.placeholder')"
        :noContentPlaceholder="i18n.t('repositories.item_card.repository_text_value.no_text')"
        :allowBlank="true"
        :smartAnnotation="false"
        :attributeName="`${colName} `"
        :allowNewLine="false"
        :singleLine="false"
        :expandable="true"
        :collapsed="collapsed"
        @editingEnabled="editing = true"
        @editingDisabled="editing = false"
        @update="update"
      ></inline-edit>
      <div v-else-if="colVal?.edit"
           ref="textRef"
           class="text-sn-dark-grey box-content font-inter text-sm font-normal leading-5 overflow-y-auto px-4 py-2 border-sn-light-grey border border-solid rounded"
           :class="{
             'max-h-[4rem]': collapsed,
             'max-h-[40rem]': !collapsed
           }"
      >
        {{ colVal?.edit }}
      </div>
      <div v-else class="text-sn-dark-grey font-inter text-sm font-normal leading-5">
        {{ i18n.t("repositories.item_card.repository_text_value.no_text") }}
      </div>
    </div>
  </div>
</template>

<script>
import InlineEdit from "../../shared/inline_edit.vue";
import repositoryValueMixin from "./mixins/repository_value.js";

export default {
  name: "RepositoryTextValue",
  mixins: [repositoryValueMixin],
  components: {
    "inline-edit": InlineEdit
  },
  data() {
    return {
      edit: null,
      view: null,
      contentExpanded: false,
      expandable: false,
      collapsed: true
    }
  },
  props: {
    data_type: String,
    colId: Number,
    colName: String,
    colVal: Object,
    permissions: null,
    inArchivedRepositoryRow: Boolean,
  },
  mounted() {
    this.$nextTick(() => {
      if (this.$refs.textRef) {
        const textHeight = this.$refs.textRef.scrollHeight
        this.expandable = textHeight > 60 // 60px
      }
      this.toggleExpandableState();
    });
  },
  watch: {
    editing() {
      if (this.editing) return;

      this.toggleExpandableState();
    }
  },
  methods: {
    toggleCollapse() {
      if (this.expandable) {
        this.collapsed = !this.collapsed;
      }
    },
    toggleExpandableState() {
      if (!this.$refs.textRef) return;
      let offsetHeight;
      let scrollHeight;

      if (Object.keys(this.$refs.textRef.$refs).length > 0) {
        const keys = Object.keys(this.$refs.textRef.$refs)
        keys.forEach((ref) => {
          if (this.$refs.textRef.$refs[ref] !== undefined) {
            offsetHeight = this.$refs.textRef.$refs[ref].offsetHeight;
            scrollHeight = this.$refs.textRef.$refs[ref].scrollHeight;
            this.expandable = scrollHeight > offsetHeight;
          }
        });
        return;
      }

      offsetHeight = this.$refs.textRef.offsetHeight;
      scrollHeight = this.$refs.textRef.scrollHeight;
      this.expandable = scrollHeight > offsetHeight;
    },
  },
};
</script>
