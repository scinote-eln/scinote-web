<template>
  <div class="flex py-4 items-center justify-between">
    <div class="flex items-center gap-4">
      <a v-for="action in toolbarActions.left" :key="action.label"
          :class="action.buttonStyle"
          :href="action.path"
          @click="doAction(action, $event)">
        <i :class="action.icon"></i>
        {{ action.label }}
      </a>
    </div>
    <div>
      <div class="flex items-center gap-2">
        <MenuDropdown
          v-if="archivedPageUrl"
          :listItems="this.viewRendersMenu"
          :btnClasses="'btn btn-light icon-btn'"
          :btnText="i18n.t(`toolbar.${currentViewRender}_view`)"
          :caret="true"
          :position="'right'"
          @setCardsView="$emit('setCardsView')"
          @setTableView="$emit('setTableView')"
        ></MenuDropdown>
        <MenuDropdown
          v-if="archivedPageUrl"
          :listItems="this.viewModesMenu"
          :btnClasses="'btn btn-light icon-btn'"
          :btnText="i18n.t(`projects.index.${currentViewMode}`)"
          :caret="true"
          :position="'right'"
        ></MenuDropdown>
      </div>
    </div>
    <div class="flex items-center gap-2">
      <a v-for="action in toolbarActions.right" :key="action.label"
          :class="action.buttonStyle"
          :href="action.path"
          @click="doAction(action, $event)">
        <i :class="action.icon"></i>
        {{ action.label }}
      </a>
      <button
        v-if="currentViewRender === 'table'"
        @click="showColumnsModal = true"
        class="btn btn-light icon-btn"
      >
        <i class="sn-icon sn-icon-reports"></i>
      </button>
      <div v-if="filters.length == 0"
           class="sci-input-container-v2"
           :class="{'w-48': showSearch, 'w-11': !showSearch}">
        <input
          ref="searchInput"
          class="sci-input-field !pr-8"
          type="text"
          @focus="openSearch"
          @blur="hideSearch"
          :value="searchValue"
          :placeholder="'Search...'"
          @change="$emit('search:change', $event.target.value)"
        />
        <i class="sn-icon sn-icon-search !m-2.5 !ml-auto right-0"></i>
      </div>
      <FilterDropdown v-else :filters="filters" @applyFilters="applyFilters" />
    </div>
    <teleport to="body">
      <ColumnsModal
        :tableState="tableState"
        :columnDefs="columnDefs"
        @hideColumn="(column) => $emit('hideColumn', column)"
        @showColumn="(column) => $emit('showColumn', column)"
        v-if="showColumnsModal"
        @close="showColumnsModal = false" />
    </teleport>
  </div>
</template>

<script>
import MenuDropdown from '../menu_dropdown.vue';
import FilterDropdown from '../filters/filter_dropdown.vue';
import ColumnsModal from './modals/columns.vue';

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
      type: Array,
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
    }
  },
  components: {
    MenuDropdown,
    FilterDropdown,
    ColumnsModal
  },
  computed: {
    viewModesMenu() {
      return [
        { text: this.i18n.t('projects.index.active'), url: this.activePageUrl },
        { text: this.i18n.t('projects.index.archived'), url: this.archivedPageUrl }
      ];
    },
    viewRendersMenu() {
      return this.viewRenders.map((view) => {
        const { type } = view;
        switch (type) {
          case 'cards':
            return { text: this.i18n.t('toolbar.cards_view'), emit: 'setCardsView' };
          case 'table':
            return { text: this.i18n.t('toolbar.table_view'), emit: 'setTableView' };
          case 'custom':
            return { text: view.name, url: view.url };
          default:
            return view;
        }
      });
    }
  },
  data() {
    return {
      showSearch: false,
      showColumnsModal: false
    };
  },
  watch: {
    searchValue() {
      if (this.searchValue.length > 0) {
        this.openSearch();
      }
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
    }
  }
};
</script>
