<template>
  <div ref="repositoryItemRelationshipsModal" @keydown.esc="cancel" id="repositoryItemRelationshipsModal" tabindex="-1" role="dialog"
    class="modal ">
    <div class="modal-dialog modal-sm" role="document">
      <div class="modal-content w-[400px] h-[498px] m-auto">

        <!-- header -->
        <div class="modal-header h-[76px] flex !flex-col gap-[6px]">

          <!-- header title with close icon -->
          <div class="h-[30px] w-full flex flex-row-reverse">
            <i id="close-icon" class="sn-icon sn-icon-close ml-auto cursor-pointer my-auto mx-0" data-dismiss="modal"
              aria-label="Close"></i>
            <h4 class="modal-title" id="modal-destroy-team-label">
              {{ i18n.t('repositories.item_card.repository_item_relationships_modal.header_title') }}
            </h4>
          </div>

          <!-- header subtitle -->
          <div class="h-10 overflow-hidden break-words text-sn-dark-grey text-sm font-normal leading-5"
            style="-webkit-box-orient: vertical; -webkit-line-clamp: 2; display: -webkit-box;">
            {{ i18n.t('repositories.item_card.repository_item_relationships_modal.header_subtitle') }}
          </div>

        </div>

        <div v-if="isLoading" class="flex justify-center h-40 w-auto">
          <div class="m-auto h-fit w-fit">{{ i18n.t('general.loading') }}</div>
        </div>

        <div v-else class="modal-body flex flex-col gap-6">
          <!-- inventory -->
          <div class="flex flex-col gap-[7px]">
            <div class="h-5 whitespace-nowrap overflow-auto">
              {{ i18n.t('repositories.item_card.repository_item_relationships_modal.inventory_section_title') }}</div>
            <div class="h-11">
              <select-search ref="ChangeSelectedInventoryDropdownSelector" @change="changeSelectedInventory"
                :value="selectedInventoryValue" :withClearButton="false" :withEditCursor="false"
                :options="inventoryOptions" :isLoading="isLoading"
                :placeholder="i18n.t('repositories.item_card.repository_item_relationships_modal.select_inventory_placeholder')"
                :noOptionsPlaceholder="i18n.t('repositories.item_card.repository_item_relationships_modal.select_inventory_no_options_placeholder')"
                :searchPlaceholder="i18n.t('repositories.item_card.repository_item_relationships_modal.select_inventory_placeholder')"
              ></select-search>
            </div>
          </div>

          <!-- item -->
          <div class="flex flex-col gap-[7px]">
            <div class="h-5 whitespace-nowrap overflow-auto">
              {{ i18n.t('repositories.item_card.repository_item_relationships_modal.item_section_title') }}</div>
            <div class="h-11">
              <checklist-select :shouldUpdateWithoutValues="true" :withButtons="false" :withEditCursor="false"
                ref="ChangeSelectedItemChecklistSelector" :options="itemOptions"
                :placeholder="i18n.t('repositories.item_card.repository_item_relationships_modal.select_item_placeholder')"
                :noOptionsPlaceholder="i18n.t('repositories.item_card.repository_item_relationships_modal.select_item_no_options_placeholder')"
                :initialSelectedValues="this.selectedItemValues.map((val) => val.id)" @update="handleUpdate"
                :shouldUpdateOnToggleClose="true"
                >
              </checklist-select>
            </div>
          </div>

          <!-- relationship -->
          <div class="flex flex-col gap-[7px]">
            <div class="h-5 whitespace-nowrap overflow-auto">
              {{ i18n.t('repositories.item_card.repository_item_relationships_modal.relationship_section_title') }}
            </div>
            <div class="h-11">
              <select-search ref="ChangeSelectedRelationshipDropdownSelector" @change="changeSelectedRelationship"
                :value="selectedRelationshipValue" :withClearButton="false" :withEditCursor="false"
                :options="relationshipOptions" :isLoading="isLoading"
                :placeholder="i18n.t('repositories.item_card.repository_item_relationships_modal.select_relationship_placeholder')"
                :noOptionsPlaceholder="i18n.t('repositories.item_card.repository_item_relationships_modal.select_relationship_no_options_placeholder')"
                :searchPlaceholder="i18n.t('repositories.item_card.repository_item_relationships_modal.select_relationship_placeholder')"
              ></select-search>
            </div>
          </div>
        </div>

        <!-- footer -->
        <div class="modal-footer">
          <div class="flex justify-end gap-4">
            <button class="btn btn-secondary w-[78px] h-10 whitespace-nowrap overflow-auto" @click="cancel">
              {{ i18n.t('repositories.item_card.repository_item_relationships_modal.cancel_button') }}
            </button>
            <button class="btn btn-primary w-[59px] h-10 whitespace-nowrap overflow-auto"
              :class="{ 'disabled': !shouldEnableAddButton }" @click="add">
              {{ i18n.t('repositories.item_card.repository_item_relationships_modal.add_button') }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import SelectSearch from '../shared/select_search.vue';
import ChecklistSelect from '../shared/checklist_select.vue';

export default {
  name: 'RepositoryItemRelationshipsModal',
  components: {
    'select-search': SelectSearch,
    'checklist-select': ChecklistSelect,
  },
  created() {
    window.repositoryItemRelationshipsModal = this;
  },
  data() {
    return {
      isLoading: false,
      selectedInventoryValue: null,
      selectedItemValues: [],
      selectedRelationshipValue: null,
      inventoryOptions: [{ 0: 1, 1: 'Participants database' }, { 0: 2, 1: 'Inventory Option 2' }, { 0: 3, 1: 'Inventory Option 3' }, { 0: 4, 1: 'Inventory Option 4' }],
      itemOptions: [{ id: 1, label: 'SEPA-STASE' }, { id: 2, label: 'GTC' }, { id: 3, label: 'DESTIL-MACRO' }, { id: 4, label: 'ARNESSLIM-L' }],
      relationshipOptions: [{ 0: 1, 1: 'Parent' }, { 0: 2, 1: 'Child' }],
    };
  },
  computed: {
    shouldEnableAddButton() {
      return ((this.selectedInventoryValue !== null) && (this.selectedRelationshipValue !== null) && (this.selectedItemValues.length > 0))
    },
  },
  methods: {
    setParentOrChild(parentOrChild) {
      const lowerCaseParentOrChild = parentOrChild.toLowerCase();
      const foundRelationshipOption = this.relationshipOptions.find((option) => option[1].toLowerCase() === lowerCaseParentOrChild);
      this.selectedRelationshipValue = foundRelationshipOption[0];
    },
    handleUpdate(selectedValues) {
      const updatedItemOptions = this.itemOptions.filter((itemOption) => selectedValues.includes(itemOption.id));
      this.selectedItemValues = updatedItemOptions;
    },
    show(parentOrChild) {
      $(this.$refs.repositoryItemRelationshipsModal).modal('show');
      if (parentOrChild) {
        this.setParentOrChild(parentOrChild);
      }
    },
    changeSelectedInventory(value) {
      this.selectedInventoryValue = value;
    },
    changeSelectedRelationship(value) {
      this.selectedRelationshipValue = value;
    },
    cancel() {
      this.selectedInventoryValue = null;
      this.selectedItemValues = [];
      this.selectedRelationshipValue = null;
      $(this.$refs.repositoryItemRelationshipsModal).modal('hide');
    },
    add() {
      $(this.$refs.repositoryItemRelationshipsModal).modal('hide');
    },
  },
};
</script>
