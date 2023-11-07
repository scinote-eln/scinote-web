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
      <text-area :initialValue="colVal?.edit"
                 :noContentPlaceholder="noContentPlaceholder"
                 :placeholder="i18n.t('repositories.item_card.repository_text_value.placeholder')"
                 :unEditableRef="`textRef`"
                 :smartAnnotation="true"
                 :sa_value="colVal?.view"
                 :expandable="expandable"
                 :collapsed="collapsed"
                 @toggleExpandableState="toggleExpandableState"
                 @update="update" />
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
import Textarea from "../../shared/Textarea.vue";

export default {
  name: "RepositoryTextValue",
  mixins: [repositoryValueMixin],
  components: {
    'text-area': Textarea,
  },
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
  computed: {
    canEdit() {
      return this.permissions?.can_manage && !this.inArchivedRepositoryRow;
    }
  },
  methods: {
    toggleCollapse() {
      if (!this.expandable) return;

      this.collapsed = !this.collapsed;
    },
    toggleExpandableState(expandable) {
      this.expandable = expandable;
    },
  },
};
</script>
