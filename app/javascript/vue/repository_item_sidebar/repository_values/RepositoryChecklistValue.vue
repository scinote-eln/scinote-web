<template>
  <div id="repository-checklist-value-wrapper"
       class="flex flex-col min-min-h-[46px] h-auto gap-[6px]">
    <div class="font-inter text-sm font-semibold leading-5 truncate">
      {{ colName }}
    </div>
    <div v-if="checklistItems.length > 0">
      <checklist-select
        v-if="permissions?.can_manage && !inArchivedRepositoryRow"
        @change="changeSelected"
        @update="update"
        :initialSelectedValues="colVal?.map(item => item.value)"
        :withButtons="true"
        :withEditCursor="true"
        ref="ChecklistSelector"
        :options="checklistItems"
        :placeholder="i18n.t('repositories.item_card.dropdown_placeholder')"
        :no-options-placeholder="i18n.t('repositories.item_card.dropdown_placeholder')"
      ></checklist-select>
      <div v-else
           class="text-sn-dark-grey font-inter text-sm font-normal leading-5 w-[370px] overflow-x-auto flex flex-wrap gap-1">
        <span v-for="(checklistItem, index) in checklistItems"
              :key="index"
              :id="`checklist-item-${index}`"
              class="flex w-fit break-words mr-1">
          {{
            index + 1 === checklistItems.length
              ? checklistItem?.label
              : `${checklistItem?.label} |`
          }}
        </span>
      </div>
    </div>
    <div v-else
         class="text-sn-dark-grey font-inter text-sm font-normal leading-5">
      {{ i18n.t("repositories.item_card.repository_checklist_value.no_checklist") }}
    </div>
  </div>
</template>

<script>
import ChecklistSelect from "../../shared/checklist_select.vue";
import repositoryValueMixin from "./mixins/repository_value.js";

export default {
  name: "RepositoryChecklistValue",
  mixins: [repositoryValueMixin],
  components: {
    "checklist-select": ChecklistSelect
  },
  props: {
    data_type: String,
    colId: Number,
    colName: String,
    colVal: Array,
    permissions: null,
    optionsPath: String,
    inArchivedRepositoryRow: Boolean,
  },
  data() {
    return {
      id: null,
      isLoading: false,
      checklistItems: [],
      selectedChecklistItems: []
    };
  },
  mounted() {
    this.fetchChecklistItems();
  },
  methods: {
    fetchChecklistItems() {
      this.isLoading = true;

      $.get(this.optionsPath, data => {
        if (Array.isArray(data)) {
          this.checklistItems = data.map(option => {
            const { value, label } = option;
            return { id: value, label: label };
          });
          return false;
        }

        this.checklistItems = [];
      }).always(() => {
        this.isLoading = false;
      });
    },
    changeSelected(selectedChecklistItems) {
      this.selectedChecklistItems = selectedChecklistItems;
    }
  }
};
</script>
