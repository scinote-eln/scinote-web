import MenuDropdown from '../menu_dropdown.vue';

// The SN icon font has no wrap-text glyph yet, so the menu inlines the one from the Inventories Figma file.
const WRAP_TEXT_PATH = [
  'M5 19V5H6V19H5ZM18 19V5H19V19H18ZM10.8692 16.8385L8.03075 14L10.8692 11.1865L11.5578 11.875L9.93275 13.5H12.7308',
  'C13.4346 13.5 14.0273 13.2593 14.5087 12.778C14.9901 12.2965 15.2308 11.7038 15.2308 11',
  'C15.2308 10.2962 14.9901 9.7035 14.5087 9.222C14.0273 8.74067 13.4346 8.5 12.7308 8.5H7.76925V7.5H12.7308',
  'C13.7026 7.5 14.5288 7.84042 15.2095 8.52125C15.8903 9.20192 16.2308 10.0282 16.2308 11',
  'C16.2308 11.9718 15.8903 12.7981 15.2095 13.4788C14.5288 14.1596 13.7026 14.5 12.7308 14.5H9.93275',
  'L11.5578 16.125L10.8692 16.8385Z'
].join('');
const WRAP_TEXT_ICON = `<svg class="shrink-0" width="24" height="24" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
  <path d="${WRAP_TEXT_PATH}"/>
</svg>`;

// Flyout rows in Figma are dark text, not the link blue MenuDropdown gives <a> items.
const menuItemHtml = (icon, text) => `<span class="flex items-center gap-2 text-sn-black">${icon}<span>${text}</span></span>`;
const fontIcon = (name) => `<i class="sn-icon sn-icon-${name} shrink-0"></i>`;

export default {
  template: `
    <div class="w-full flex items-center group gap-1 h-full"
         :class="{'cursor-pointer': params.enableSorting}"
         :data-e2e="'e2e-CO-tableHeader-' + params.column.colId "
         @click="onSortRequested(nextSort(), $event)">
      <div v-if="params.html" class="customHeaderLabel truncate grow" v-html="params.html"></div>
      <div v-else class="customHeaderLabel truncate grow">{{ params.displayName }}</div>
      <div v-if="activeSort == 'asc'" class="customSortDownLabel text-sn-black shrink-0" data-e2e="e2e-BT-tableHeader-sortedAsc">
        <i class="sn-icon sn-icon-sort-up"></i>
      </div>
      <div v-if="activeSort == 'desc'" class="customSortUpLabel text-sn-black shrink-0" data-e2e="e2e-BT-tableHeader-sortedDesc">
        <i class="sn-icon sn-icon-sort-down"></i>
      </div>
      <div v-if="activeSort == null && params.enableSorting" class="text-sn-black tw-hidden group-hover:block shrink-0" data-e2e="e2e-BT-tableHeader-sortUpDown">
        <i class="sn-icon sn-icon-sort"></i>
      </div>
      <div v-if="params.columnMenu"
           class="shrink-0"
           :class="{ 'opacity-0 group-hover:opacity-100': !menuOpen }"
           @click.stop>
        <MenuDropdown
          :listItems="menuItems"
          :alwaysShow="true"
          position="right"
          btnClasses="btn btn-light icon-btn btn-xs !bg-transparent"
          btnIcon="sn-icon sn-icon-more-vert"
          :title="i18n.t('datatable.column_menu.title')"
          :dataE2e="'e2e-BT-tableHeader-' + params.column.colId + '-columnMenu'"
          @menu-toggle="menuOpen = $event"
          @pinColumn="dtComponent.pinColumn({ field: colId })"
          @unpinColumn="dtComponent.unPinColumn({ field: colId })"
          @wrapText="dtComponent.setColumnWrapped(colId, true)"
          @unwrapText="dtComponent.setColumnWrapped(colId, false)"
          @sortDesc="params.setSort('desc', false)"
          @sortAsc="params.setSort('asc', false)"
          @hideColumn="dtComponent.hideColumn({ field: colId })"
        />
      </div>
    </div>
  `,
  components: { MenuDropdown },
  data() {
    return {
      activeSort: null,
      pinned: null,
      menuOpen: false
    };
  },
  computed: {
    dtComponent() {
      return this.params.dtComponent;
    },
    colId() {
      return this.params.column.getColId();
    },
    wrapped() {
      return !!this.dtComponent?.wrappedColumns?.includes(this.colId);
    },
    menuItems() {
      // emit doubles as the MenuDropdown event and the e2e suffix; key is the i18n key.
      const item = (icon, key, emit, active = false) => ({
        text: menuItemHtml(icon, this.i18n.t(`datatable.column_menu.${key}`)),
        emit,
        active,
        data_e2e: `e2e-BT-tableHeader-${this.colId}-${emit}`
      });
      const items = [];

      items.push(this.pinned ? item(fontIcon('pinned'), 'unpin', 'unpinColumn') : item(fontIcon('pin'), 'pin', 'pinColumn'));

      if (this.params.wrappable) {
        items.push(this.wrapped
          ? item(WRAP_TEXT_ICON, 'unwrap_text', 'unwrapText')
          : item(WRAP_TEXT_ICON, 'wrap_text', 'wrapText'));
      }

      if (this.params.enableSorting) {
        items.push(item(fontIcon('sort-down'), 'sort_down', 'sortDesc', this.activeSort === 'desc'));
        items.push(item(fontIcon('sort-up'), 'sort_up', 'sortAsc', this.activeSort === 'asc'));
      }

      if (this.params.hideable) items.push(item(fontIcon('visibility-show'), 'hide', 'hideColumn'));

      return items;
    }
  },
  mounted() {
    this.params.column.addEventListener('sortChanged', this.onSortChanged);
    this.params.column.addEventListener('columnStateUpdated', this.onPinnedChanged);
    this.onSortChanged();
    this.onPinnedChanged();
  },
  beforeUnmount() {
    this.params.column.removeEventListener('sortChanged', this.onSortChanged);
    this.params.column.removeEventListener('columnStateUpdated', this.onPinnedChanged);
  },
  methods: {
    onSortChanged() {
      this.activeSort = null;
      if (this.params.column.isSortAscending()) {
        this.activeSort = 'asc';
      } else if (this.params.column.isSortDescending()) {
        this.activeSort = 'desc';
      }
    },
    onPinnedChanged() {
      this.pinned = this.params.column.getPinned();
    },
    nextSort() {
      if (this.activeSort === 'asc') return 'desc';
      // With the column menu on, a header click cycles asc → desc → unsorted, like AG Grid's default.
      if (this.activeSort === 'desc' && this.params.columnMenu) return null;

      return 'asc';
    },
    onSortRequested(order, event) {
      if (!this.params.enableSorting) return;

      this.params.setSort(order, event.shiftKey);
    }
  }
};
