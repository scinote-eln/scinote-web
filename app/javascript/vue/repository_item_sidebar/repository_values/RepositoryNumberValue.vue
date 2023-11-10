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
        <text-area :initialValue="(colVal)?.toLocaleString('fullwide', {useGrouping:false}) || ''"
                   :noContentPlaceholder="noContentPlaceholder"
                   :placeholder="i18n.t('repositories.item_card.repository_number_value.placeholder')"
                   :decimals="decimals"
                   :isNumber="true"
                   :unEditableRef="`numberRef`"
                   :expandable="expandable"
                   :collapsed="collapsed"
                   @toggleExpandableState="toggleExpandableState"
                   @update="update" />
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
import Textarea from "../../shared/Textarea.vue";

export default {
  name: "RepositoryNumberValue",
  mixins: [repositoryValueMixin],
  components: {
    'text-area': Textarea,
  },
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
    colVal: Number,
    permissions: null,
    inArchivedRepositoryRow: Boolean,
  },
  created() {
    // constants
    this.noContentPlaceholder = this.i18n.t("repositories.item_card.repository_number_value.no_number");
    this.decimals = Number(document.getElementById(`${this.colId}`).dataset['metadataDecimals']) || 0;
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
  }
};
</script>
