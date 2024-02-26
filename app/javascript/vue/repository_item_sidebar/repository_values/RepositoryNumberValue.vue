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
    <div v-if="canEdit" class="w-full contents">
      <text-area :initialValue="(colVal)?.toLocaleString('fullwide', {useGrouping:false}) || ''"
                  :noContentPlaceholder="i18n.t('repositories.item_card.repository_number_value.placeholder')"
                  :placeholder="i18n.t('repositories.item_card.repository_number_value.placeholder')"
                  :decimals="decimals"
                  :isNumber="true"
                  :unEditableRef="`numberRef`"
                  :expandable="expandable"
                  :collapsed="collapsed"
                  @toggleExpandableState="toggleExpandableState"
                  @update="update"
                  className="px-3"
                  :data-e2e="'e2e-IF-repoItemSBcustomColumns-input' + colId"
                />
    </div>
    <div v-else-if="colVal"
          ref="numberRef"
          class="text-sn-dark-grey box-content font-inter text-sm font-normal leading-5 min-h-[20px] overflow-y-auto"
          :class="{
            'max-h-[4rem]': collapsed,
            'max-h-[40rem]': !collapsed
          }">
      {{ colval }}
    </div>
    <div v-else
          class="text-sn-dark-grey font-inter text-sm font-normal leading-5">
      {{ i18n.t("repositories.item_card.repository_number_value.no_number") }}
    </div>
  </div>
</template>

<script>
import repositoryValueMixin from './mixins/repository_value.js';
import Textarea from '../../shared/legacy/Textarea.vue';

export default {
  name: 'RepositoryNumberValue',
  mixins: [repositoryValueMixin],
  components: {
    'text-area': Textarea
  },
  data() {
    return {
      expandable: false,
      collapsed: true,
      numberValue: ''
    };
  },
  props: {
    data_type: String,
    colId: Number,
    colName: String,
    colVal: Number,
    permissions: null,
    decimals: { type: Number, default: 0 },
    canEdit: { type: Boolean, default: false }
  },
  mounted() {
    const maxCollapsedHeight = 60;
    const numberRefEl = this.$refs.numberRef;
    this.$nextTick(() => {
      if (!numberRefEl) return;
      const isExpandable = numberRefEl.scrollHeight > maxCollapsedHeight;
      this.expandable = isExpandable;
    });
  },
  methods: {
    toggleCollapse() {
      if (!this.expandable) return;

      this.collapsed = !this.collapsed;
    },
    toggleExpandableState(expandable) {
      this.expandable = expandable;
    }
  }
};
</script>
