<template>
  <div
    v-if="canConnectRows"
    ref="repositoryItemRelationshipsModal"
    @keydown.esc="close"
    id="repositoryItemRelationshipsModal"
    tabindex="-1"
    role="dialog"
    class="modal">
    <div class="modal-dialog modal-sm" role="document">
      <div class="modal-content w-[400px] m-auto" v-click-outside="handleClickOutside">

        <!-- header -->
        <div class="modal-header h-[76px] flex !flex-col gap-[6px]">

          <!-- header title with close icon -->
          <div class="h-[30px] w-full flex flex-row-reverse">
            <i id="close-icon" class="sn-icon sn-icon-close ml-auto cursor-pointer my-auto mx-0" data-dismiss="modal"
              aria-label="Close" @click="close"></i>
            <h4 class="modal-title" id="modal-destroy-team-label">
              {{ i18n.t('repositories.item_card.repository_item_relationships_modal.header_title') }}
            </h4>
          </div>

          <!-- header subtitle -->
          <div class="h-10 overflow-hidden break-words text-sn-dark-grey text-sm font-normal leading-5 self-start"
            style="-webkit-box-orient: vertical; -webkit-line-clamp: 2; display: -webkit-box;">
            {{ i18n.t('repositories.item_card.repository_item_relationships_modal.header_subtitle') }}
          </div>

        </div>

        <div class="modal-body flex flex-col gap-6" :class="{ '!pb-3': notification }">
          <!-- inventory -->
          <div class="flex flex-col gap-[7px]">
            <div class="h-5 whitespace-nowrap overflow-auto">
              {{ i18n.t('repositories.item_card.repository_item_relationships_modal.inventory_section_title') }}</div>
            <div class="h-11">
              <select-search ref="ChangeSelectedInventoryDropdownSelector" :value="selectedInventoryValue"
                :options="inventoryOptions"
                :isLoading="isLoadingInventories"
                :lazyLoadEnabled="true"
                :optionsUrl="inventoriesUrl"
                optionsClassName="inventory-options"
                :placeholder="i18n.t('repositories.item_card.repository_item_relationships_modal.select_inventory_placeholder')"
                :noOptionsPlaceholder="i18n.t('repositories.item_card.repository_item_relationships_modal.select_inventory_no_options_placeholder')"
                :searchPlaceholder="i18n.t('repositories.item_card.repository_item_relationships_modal.select_inventory_placeholder')"
                @update-options="updateInventories"
                @reached-end="fetchInventories"
                @change="changeSelectedInventory"
                data-e2e="e2e-DD-repoItemRelationshipsMD-inventory"
              ></select-search>
            </div>
          </div>

          <!-- item -->
          <div class="flex flex-col gap-[7px]">
            <div class="h-5 whitespace-nowrap overflow-auto">
              {{ i18n.t('repositories.item_card.repository_item_relationships_modal.item_section_title') }}</div>
            <div class="h-11">
              <ChecklistSearch
                ref="ChangeSelectedItemChecklistSelector"
                :shouldUpdateWithoutValues="true"
                :lazyLoadEnabled="true"
                :withButtons="false"
                :withEditCursor="false"
                optionsClassName="item-options"
                :optionsUrl="inventoryItemsUrl"
                :options="itemOptions"
                :placeholder="i18n.t('repositories.item_card.repository_item_relationships_modal.select_item_placeholder')"
                :noOptionsPlaceholder="i18n.t('repositories.item_card.repository_item_relationships_modal.select_item_no_options_placeholder')"
                :initialSelectedValues="selectedItemValues"
                :shouldUpdateOnToggleClose="true"
                :params="itemParams"
                @update-options="updateInventoryItems"
                @update="selectedItemValues = $event"
                @reached-end="() => fetchInventoryItems(selectedInventoryValue)"
                :disabled="!this.selectedInventoryValue"
                data-e2e="e2e-DC-repoItemRelationshipsMD-item"
              ></ChecklistSearch>
            </div>
          </div>

          <!-- relationship -->
          <div class="flex flex-col gap-[7px]">
            <div class="h-5 whitespace-nowrap overflow-auto">
              {{ i18n.t('repositories.item_card.repository_item_relationships_modal.relationship_section_title') }}
            </div>
            <div class="h-11">
              <Select
                ref="ChangeSelectedRelationshipDropdownSelector"
                class="hover:border-sn-sleepy-grey"
                @change="selectedRelationshipValue = $event"
                :value="selectedRelationshipValue"
                :options="[['parent', 'Parent'], ['child', 'Child']]"
                :placeholder="i18n.t('repositories.item_card.repository_item_relationships_modal.select_relationship_placeholder')"
                data-e2e="e2e-DD-repoItemRelationshipsMD-relationship"
              ></Select>
            </div>
          </div>
        </div>

        <!-- Notification -->
        <template v-if="notification">
          <hr class="bg-sn-light-grey mb-6 mt-3" />
          <div class="w-full mb-6">
            <div class="flex align-center gap-2.5">
              <img class="w-6 h-6" :src="notificationIconPath" alt="warning" />
              <span class="my-auto">{{ notification.message }}</span>
            </div>
            <div v-html="notification.support_html" class="pl-2.5"></div>
          </div>
        </template>

        <!-- footer -->
        <div class="modal-footer">
          <div class="flex justify-end gap-4">
            <button class="btn btn-secondary w-[78px] h-10 whitespace-nowrap" @click="close" data-e2e="e2e-BT-repoItemRelationshipsMD-cancel">
              {{ i18n.t('repositories.item_card.repository_item_relationships_modal.cancel_button') }}
            </button>
            <button class="btn btn-primary w-[59px] h-10 whitespace-nowrap"
              :class="{ 'disabled': !shouldEnableAddButton }" @click="() => addRelation(selectedRelationshipValue)" data-e2e="e2e-BT-repoItemRelationshipsMD-add">
              {{ i18n.t('repositories.item_card.repository_item_relationships_modal.add_button') }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import SelectSearch from '../shared/legacy/select_search.vue';
import ChecklistSearch from '../shared/legacy/checklist_search.vue';
import Select from '../shared/legacy/select.vue';

export default {
  name: 'RepositoryItemRelationshipsModal',
  components: {
    'select-search': SelectSearch,
    ChecklistSearch,
    Select
  },
  created() {
    window.repositoryItemRelationshipsModal = this;
  },
  data() {
    return {
      isLoadingInventories: false,
      inventoriesUrl: '',
      inventoryItemsUrl: '',
      createConnectionUrl: '',
      createConnectionUrlValue: '',
      selectedInventoryValue: null,
      selectedItemValues: [],
      selectedRelationshipValue: null,
      inventoryOptions: [],
      itemOptions: [],
      nextInventoriesPage: 1,
      nextItemsPage: 1,
      itemParams: [],
      notification: null,
      notificationIconPath: null,
      canConnectRows: null
    };
  },
  computed: {
    shouldEnableAddButton() {
      return (this.selectedInventoryValue && (this.selectedRelationshipValue !== null) && (this.selectedItemValues.length > 0));
    }
  },
  methods: {
    handleClickOutside() {
      this.selectedInventoryValue = null;
      this.resetSelectedItemValues();
    },
    fetchInventories() {
      if (!this.nextInventoriesPage) return;

      this.loadingInventories = true;
      $.ajax({
        url: this.inventoriesUrl,
        data: {
          page: this.nextInventoriesPage
        },
        success: (result) => {
          this.inventoryOptions = this.inventoryOptions.concat(result.data.map((val) => [val.id, val.name]));
          this.loadingInventories = false;
          this.nextInventoriesPage = result.next_page;
        }
      });
    },
    fetchInventoryItems(inventoryValue = null) {
      if (!inventoryValue || !this.nextItemsPage) return;

      this.loadingItems = true;
      $.ajax({
        url: this.inventoryItemsUrl,
        data: {
          page: this.nextItemsPage,
          selected_repository_id: inventoryValue
        },
        success: (result) => {
          this.itemOptions = this.itemOptions.concat(result.data.map((val) => ({ id: val.id, label: val.name })));
          this.loadingItems = false;
          this.nextItemsPage = result.next_page;
        }
      });
    },
    updateInventories(currentOptions, result) {
      this.inventoryOptions = currentOptions.concat(result.data?.map((val) => [val.id, val.name]));
    },
    updateInventoryItems(currentOptions, result) {
      this.itemOptions = currentOptions.concat(result.data.map(({ id, name }) => ({ id, label: name })));
    },
    show(params = {}) {
      const {
        relation,
        optionUrls,
        addRelationCallback,
        notificationIconPath,
        notification,
        canConnectRows
      } = params;
      this.inventoriesUrl = optionUrls.inventories_url;
      this.inventoryItemsUrl = optionUrls.inventory_items_url;
      this.createConnectionUrl = optionUrls.create_url;
      this.addRelationCallback = addRelationCallback;
      this.notificationIconPath = notificationIconPath;
      this.notification = notification;
      this.canConnectRows = canConnectRows;
      this.$nextTick(() => {
        $(this.$refs.repositoryItemRelationshipsModal).modal('show');
      });

      if (['parent', 'child'].includes(relation)) {
        this.selectedRelationshipValue = relation;
      }
      this.$nextTick(() => {
        this.fetchInventories();
      });
    },
    changeSelectedInventory(value) {
      if (value === this.selectedInventoryValue) return;

      this.selectedInventoryValue = value;
      this.resetSelectedItemValues();
      this.itemOptions = [];
      this.nextItemsPage = 1;
      if (value) {
        this.loadingItems = true;
        this.itemParams = { selected_repository_id: value };
      }
      this.$nextTick(() => {
        this.fetchInventoryItems(value);
      });
    },
    close() {
      Object.assign(this.$data, {
        selectedInventoryValue: null,
        selectedItemValues: [],
        selectedRelationshipValue: null,
        nextInventoriesPage: 1,
        nextItemsPage: 1,
        inventoriesUrl: '',
        inventoryItemsUrl: '',
        createConnectionUrl: '',
        itemOptions: [],
        inventoryOptions: [],
        itemParams: [],
        canConnectRows: null
      });
      $(this.$refs.repositoryItemRelationshipsModal).modal('hide');
    },
    addRelation(relation) {
      const $this = this;
      $.ajax({
        url: this.createConnectionUrl,
        method: 'POST',
        dataType: 'json',
        data: {
          repository_row_connection: {
            relation: this.selectedRelationshipValue,
            relation_ids: this.selectedItemValues,
            connection_repository_id: this.selectedInventoryValue
          }
        },
        success: (result) => {
          $this.addRelationCallback(result, relation);
          if ($('.dataTable.repository-dataTable')[0]) $('.dataTable.repository-dataTable').DataTable().ajax.reload(null, false);
        }
      });
      this.close();
    },
    resetSelectedItemValues() {
      this.selectedItemValues = [];
    }
  }
};
</script>
