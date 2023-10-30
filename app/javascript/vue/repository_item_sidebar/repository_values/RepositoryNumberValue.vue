<template>
  <div id="repository-number-value-wrapper"
       class="flex flex-col min-h-[46px] h-auto gap-[6px]"
  >
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
    <div>
      <inline-edit
        v-if="permissions?.can_manage && !inArchivedRepositoryRow"
        ref="numberRef"
        :value="colVal"
        :placeholder="i18n.t('repositories.item_card.repository_number_value.placeholder')"
        :noContentPlaceholder="i18n.t('repositories.item_card.repository_number_value.no_number')"
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
      <div v-else-if="colVal"
           ref="numberRef"
           class="text-sn-dark-grey box-content font-inter text-sm font-normal leading-5 min-h-[20px] overflow-y-auto"
           :class="{
             'max-h-[4rem]': collapsed,
             'max-h-[40rem]': !collapsed
           }"
      >
        {{ colVal }}
      </div>
      <div v-else
           class="text-sn-dark-grey font-inter text-sm font-normal leading-5">
        {{ i18n.t("repositories.item_card.repository_number_value.no_number") }}
      </div>
    </div>
  </div>
</template>

<script>
import InlineEdit from "../../shared/inline_edit.vue";
import repositoryValueMixin from "./mixins/repository_value.js";

export default {
  name: "RepositoryNumberValue",
  mixins: [repositoryValueMixin],
  components: {
    "inline-edit": InlineEdit
  },
  props: {
    data_type: String,
    inArchivedRepository: Boolean,
    colId: Number,
    colName: String,
    colVal: String,
    permissions: null,
    inArchivedRepositoryRow: Boolean,
  },
  data() {
    return {
      expandable: false,
      collapsed: true
    };
  },
  mounted() {
    this.$nextTick(() => {
      this.toggleExpandableState()
    });
  },
  updated() {
    this.$nextTick(() => {
      this.toggleExpandableState();
    });
  },
  methods: {
    toggleCollapse() {
      if (this.expandable) {
        this.collapsed = !this.collapsed;
      }
    },
    toggleExpandableState() {
      if (!this.$refs.numberRef) return;

      const offsetHeight = this.$refs.numberRef.offsetHeight;
      const scrollHeight = this.$refs.numberRef.scrollHeight;
      this.expandable = scrollHeight > offsetHeight;
    }
  }
};
</script>
