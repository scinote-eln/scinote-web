<template>
  <div class="flex py-4 items-center justify-between" data-e2e="e2e-CO-topToolbar">
    <div class="flex flex-1 items-center gap-4">
      <template v-for="action in toolbarActions.left" :key="action.label">
        <a v-if="action.type === 'emit' || action.type === 'link'"
           :class="[action.buttonStyle, {
            'disabled': disabled
           }]"
           :href="action.path"
           :data-e2e="`e2e-BT-topToolbar-${action.name}`"
           @click="doAction(action, $event)">
          <i :class="action.icon"></i>
          <span class="tw-hidden lg:inline">{{ action.label }}</span>
        </a>
        <MenuDropdown
          v-if="action.type === 'menu'"
          :listItems="action.menuItems"
          :btnClasses="action.buttonStyle"
          :btnText="action.label"
          :btnIcon="action.icon"
          :disabled="disabled"
          :caret="true"
          :position="'right'"
          :data-e2e="`e2e-BT-topToolbar-${action.name}`"
          @dtEvent="handleEvent"
        ></MenuDropdown>
      </template>
    </div>
    <div class="flex-none">
      <div class="flex items-center gap-2">
        <MenuDropdown
          v-if="viewRenders"
          :listItems="this.viewRendersMenu"
          :btnClasses="'btn btn-secondary !border-sn-light-grey px-3'"
          :btnText="i18n.t(`toolbar.${currentViewRender}_view`)"
          :caret="true"
          :disabled="disabled"
          :position="'right'"
          :data-e2e="'e2e-DD-topToolbar-viewDropdown'"
          @setCardsView="$emit('setCardsView')"
          @setTableView="$emit('setTableView')"
        ></MenuDropdown>
        <MenuDropdown
          v-if="archivedPageUrl"
          :listItems="this.viewModesMenu"
          :btnClasses="'btn btn-secondary !border-sn-light-grey px-3'"
          :btnText="i18n.t(`toolbar.${currentViewMode}_state`)"
          :caret="true"
          :position="'right'"
          :data-e2e="'e2e-DD-topToolbar-stateDropdown'"
        ></MenuDropdown>
      </div>
    </div>
    <div class="flex flex-1 justify-end gap-2">
      <a v-for="action in toolbarActions.right" :key="action.label"
      :class="[action.buttonStyle, {
            'disabled': disabled
           }]"
          :href="action.path"
          @click="doAction(action, $event)">
        <i :class="action.icon"></i>
        {{ action.label }}
      </a>
      <div v-if="!disabled" class="sci-input-container-v2"
           :class="{'w-48': showSearch, 'w-11': !showSearch}"
           :data-e2e="'e2e-BT-topToolbar-search'">
        <input
          ref="searchInput"
          class="sci-input-field !pr-9"
          type="text"
          @focus="openSearch"
          @blur="hideSearch"
          :value="searchValue"
          :placeholder="'Search...'"
          :data-e2e="'e2e-IF-topToolbar-search'"
          @change="$emit('search:change', $event.target.value)"
        />
        <i v-if="searchValue.length === 0" class="sn-icon sn-icon-search !m-2.5 !ml-auto right-0"></i>
        <i v-else class="sn-icon sn-icon-close !m-2.5 !ml-auto right-0 cursor-pointer z-10"
                  @click="$emit('search:change', '')"></i>
      </div>
      <FilterDropdown v-if="filters.length && !disabled" :filters="filters" @applyFilters="applyFilters" :data-e2e="'e2e-BT-topToolbar-filters'"/>
      <button
        v-if="currentViewRender === 'table' && !hideColumnsManagment"
        @click="showColumnsModal = true"
        :disabled="disabled"
        :data-e2e="'e2e-BT-topToolbar-manageColumns'"
        :title="i18n.t('experiments.table.column_display_modal.title')"
        class="btn btn-light icon-btn btn-black"
      >
        <i class="sn-icon sn-icon-manage-columns"></i>
      </button>
      <GeneralDropdown v-if="currentViewRender === 'cards'" ref="dropdown" position="right">
        <template v-slot:field>
          <button class="btn btn-light icon-btn btn-black" :disabled="disabled">
            <i class="sn-icon sn-icon-sort-down"></i>
          </button>
        </template>
        <template v-slot:flyout >
          <div class="min-w-[12rem]">
            <div v-for="col in sortableColumns"
                class="flex whitespace-nowrap rounded px-3 py-2.5 hover:!text-sn-blue items-center h-11
                        hover:no-underline cursor-pointer hover:bg-sn-super-light-grey leading-5"
                :key="col.field"
                @click="$emit('sort', col.field, (order?.dir === 'asc' ? 'desc' : 'asc'))">
              <span>{{ col.headerName }}</span>
              <div v-if="order && order.column === col.field" class="ml-auto">
                <i v-if="order.dir === 'asc'" class="sn-icon sn-icon-sort-up"></i>
                <i v-else class="sn-icon sn-icon-sort-down"></i>
              </div>
            </div>
          </div>
        </template>
      </GeneralDropdown>
    </div>
    <teleport to="body">
      <ColumnsModal
        :tableState="tableState"
        :columnDefs="columnDefs"
        @hideColumn="(column) => $emit('hideColumn', column)"
        @showColumn="(column) => $emit('showColumn', column)"
        @unPinColumn="(column) => $emit('unPinColumn', column)"
        @pinColumn="(column) => $emit('pinColumn', column)"
        @reorderColumns="(columns) => $emit('reorderColumns', columns)"
        @resetToDefault="resetToDefault"
        v-if="showColumnsModal"
        @close="showColumnsModal = false" />
    </teleport>
    <teleport to="body">
      <ConfirmationModal
        :title="i18n.t('experiments.table.column_display_modal.confirmation.title')"
        :description="i18n.t('experiments.table.column_display_modal.confirmation.description_html')"
        confirmClass="btn btn-primary"
        :confirmText="i18n.t('experiments.table.column_display_modal.confirmation.confirm')"
        ref="resetColumnModal"
      ></ConfirmationModal>
    </teleport>
  </div>
</template>

<script>
import MenuDropdown from '../menu_dropdown.vue';
import GeneralDropdown from '../general_dropdown.vue';
import FilterDropdown from '../filters/filter_dropdown.vue';
import ColumnsModal from './modals/columns.vue';
import ConfirmationModal from '../confirmation_modal.vue';

export default {
  name: 'Toolbar',
  props: {
    toolbarActions: {
      type: Object,
      required: true
    },
    searchValue: {
      type: String
    },
    activePageUrl: {
      type: String
    },
    archivedPageUrl: {
      type: String
    },
    currentViewMode: {
      type: String,
      default: 'active'
    },
    filters: {
      type: Array,
      default: () => []
    },
    viewRenders: {
      required: true
    },
    currentViewRender: {
      type: String,
      required: true
    },
    columnDefs: {
      type: Array,
      required: true
    },
    tableState: {
      type: Object
    },
    order: {
      type: Object
    },
    disabled: {
      type: Boolean,
      default: false
    },
    hideColumnsManagment: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      showSearch: false,
      showColumnsModal: false
    };
  },
  components: {
    MenuDropdown,
    FilterDropdown,
    ColumnsModal,
    GeneralDropdown,
    ConfirmationModal
  },
  computed: {
    viewModesMenu() {
      return [
        {
          text: this.i18n.t('toolbar.active_state'),
          url: this.activePageUrl,
          active: this.currentViewMode === 'active',
          data_e2e: 'e2e-BT-topToolbar-viewState-active'
        },
        {
          text: this.i18n.t('toolbar.archived_state'),
          url: this.archivedPageUrl,
          active: this.currentViewMode === 'archived',
          data_e2e: 'e2e-BT-topToolbar-viewState-archived'
        }
      ];
    },
    viewRendersMenu() {
      return this.viewRenders.map((view) => {
        const { type } = view;
        const active = this.currentViewRender === type;
        switch (type) {
          case 'cards':
            return {
              text: this.i18n.t('toolbar.cards_view'),
              emit: 'setCardsView',
              active,
              data_e2e: 'e2e-BT-topToolbar-view-cards'
            };
          case 'table':
            return {
              text: this.i18n.t('toolbar.table_view'),
              emit: 'setTableView',
              active,
              data_e2e: 'e2e-BT-topToolbar-view-table'
            };
          case 'custom':
            return { text: view.name, url: view.url, active };
          default:
            return view;
        }
      });
    },
    sortableColumns() {
      return this.columnDefs.filter((column) => column.sortable);
    }
  },
  watch: {
    searchValue() {
      if (this.searchValue.length > 0) {
        this.openSearch();
      }
    }
  },
  mounted() {
    if (this.searchValue.length > 0) {
      this.openSearch();
    }
  },
  methods: {
    openSearch() {
      this.showSearch = true;
    },
    hideSearch() {
      if (this.searchValue.length === 0) {
        this.showSearch = false;
      }
    },
    doAction(action, event) {
      switch (action.type) {
        case 'emit':
          event.preventDefault();
          this.$emit('toolbar:action', action);
          break;
        case 'link':
          break;
        default:
          break;
      }
    },
    applyFilters(filters) {
      this.$emit('applyFilters', filters);
    },
    handleEvent(event) {
      this.$emit('toolbar:action', { name: event });
    },
    async resetToDefault() {
      const ok = await this.$refs.resetColumnModal.show();
      if (ok) {
        this.$emit('resetColumnsToDefault');
      }
      this.showColumnsModal = true;
    }
  }
};
</script>
