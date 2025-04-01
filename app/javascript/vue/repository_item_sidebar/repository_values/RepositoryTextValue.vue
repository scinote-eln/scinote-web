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
    <text-area :initialValue="colVal?.edit"
                :noContentPlaceholder="i18n.t('repositories.item_card.repository_text_value.placeholder')"
                :placeholder="i18n.t('repositories.item_card.repository_text_value.placeholder')"
                :unEditableRef="`textRef`"
                :smartAnnotation="true"
                :expandable="expandable"
                :collapsed="collapsed"
                @toggleExpandableState="toggleExpandableState"
                @update="update"
                className="px-3"
                :data-e2e="'e2e-IF-repoItemSBcustomColumns-input' + colId"
              />
  </div>
</template>

<script>
import repositoryValueMixin from './mixins/repository_value.js';
import Textarea from '../../shared/legacy/Textarea.vue';

export default {
  name: 'RepositoryTextValue',
  mixins: [repositoryValueMixin],
  components: {
    'text-area': Textarea
  },
  data() {
    return {
      expandable: false,
      collapsed: true,
      textValue: ''
    };
  },
  props: {
    data_type: String,
    colId: Number,
    colName: String,
    colVal: Object,
    canEdit: { type: Boolean, default: false }
  },
  created() {
    // constants
    this.noContentPlaceholder = this.i18n.t('repositories.item_card.repository_text_value.no_text');
  },
  mounted() {
    const maxCollapsedHeight = 60;
    const textRefEl = this.$refs.textRef;
    this.$nextTick(() => {
      if (!textRefEl) return;
      const isExpandable = textRefEl.scrollHeight > maxCollapsedHeight;
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
