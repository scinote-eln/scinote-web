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
      <div class="modal-content w-[400px] m-auto">

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
          <RepositoryRowSelector
            :multiple="true"
            :manageableRepositoriesOnly="true"
            @change="selectedItemValues = $event"
            @repositoryChange="changeSelectedInventory"
          />
          <!-- relationship -->
          <div class="flex flex-col gap-[7px]">
            <div class="h-5 whitespace-nowrap overflow-auto">
              {{ i18n.t('repositories.item_card.repository_item_relationships_modal.relationship_section_title') }}
            </div>
            <div class="h-11">
              <SelectDropdown
                ref="ChangeSelectedRelationshipDropdownSelector"
                class="hover:border-sn-sleepy-grey"
                :value="selectedRelationshipValue"
                :options="[['parent', 'Parent'], ['child', 'Child']]"
                :placeholder="i18n.t('repositories.item_card.repository_item_relationships_modal.select_relationship_placeholder')"
                @change="selectedRelationshipValue = $event"
                data-e2e="e2e-DD-repoItemRelationshipsMD-relationship"
              />
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
import SelectDropdown from '../shared/select_dropdown.vue';
import RepositoryRowSelector from '../shared/repository_row_selector.vue';

export default {
  name: 'RepositoryItemRelationshipsModal',
  components: {
    SelectDropdown,
    RepositoryRowSelector
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
      return (this.selectedInventoryValue && (this.selectedRelationshipValue !== null) && (this.selectedItemValues && this.selectedItemValues.length > 0));
    }
  },
  methods: {
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
    },
    changeSelectedInventory(value) {
      if (value === this.selectedInventoryValue) return;
      this.selectedInventoryValue = value;
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
    }
  }
};
</script>
