<template>
  <div id="repository-checklist-value-wrapper" class="flex flex-col min-min-h-[46px] h-auto gap-[6px]">
    <div class="font-inter text-sm font-semibold leading-5 truncate" :title="colName">
      {{ colName }}
    </div>
    <div v-if="canEdit">
      <select-dropdown
        @change="handleChange"
        :options="availableChecklistItems"
        :value="selectedChecklistItemsIds"
        :with-checkboxes="true"
        :multiple="true"
        :clearable="true"
        :size="'sm'"
        >
      </select-dropdown>
    </div>
    <div v-else-if="computedArrOfItemObjects && computedArrOfItemObjects.length > 0"
         class="text-sn-dark-grey font-inter text-sm font-normal leading-5 w-[370px] overflow-x-auto flex flex-wrap gap-1">
      <span v-for="(checklistItem, index) in computedArrOfItemObjects"
            :key="index"
            :id="`checklist-item-${index}`"
            class="flex w-fit break-words">
        {{
          index + 1 === computedArrOfItemObjects.length
            ? checklistItem?.label
            : `${checklistItem?.label} |`
        }}
      </span>
    </div>
    <div v-else
         class="text-sn-dark-grey font-inter text-sm font-normal leading-5">
      {{ i18n.t("repositories.item_card.repository_checklist_value.no_checklist") }}
    </div>
  </div>
</template>

<script>
import SelectDropdown from '../../shared/select_dropdown.vue';
import repositoryValueMixin from './mixins/repository_value.js';

export default {
  name: 'RepositoryChecklistValue',
  mixins: [repositoryValueMixin],
  components: { 'select-dropdown': SelectDropdown },
  props: {
    data_type: String,
    colId: Number,
    colName: String,
    colVal: Array,
    optionsPath: String,
    canEdit: Boolean
  },
  data() {
    return {
      id: null,
      isLoading: false,
      availableChecklistItems: [],
      selectedChecklistItemsIds: []
    };
  },
  mounted() {
    this.fetchChecklistItems();
    if (this.colVal && Array.isArray(this.colVal)) {
      this.selectedChecklistItemsIds = this.colVal.map((item) => String(item.value));
    }
  },
  computed: {
    computedArrOfItemObjects() {
      const arrOfItemObjects = this.selectedChecklistItemsIds.map((id) => {
        const matchingItem = this.availableChecklistItems.find((item) => item[0] === id);
        return {
          id: matchingItem ? matchingItem[0] : null,
          label: matchingItem ? matchingItem[1] : null
        };
      });
      return arrOfItemObjects;
    }
  },
  methods: {
    fetchChecklistItems() {
      this.isLoading = true;

      $.get(this.optionsPath, (data) => {
        if (Array.isArray(data)) {
          this.availableChecklistItems = data.map((option) => [String(option.value), option.label]);
          return false;
        }

        this.availableChecklistItems = [];
      }).always(() => {
        this.isLoading = false;
      });
    },
    handleChange(selectedChecklistItemsIds) {
      this.selectedChecklistItemsIds = selectedChecklistItemsIds;
      this.update(selectedChecklistItemsIds);
    }
  }
};
</script>
