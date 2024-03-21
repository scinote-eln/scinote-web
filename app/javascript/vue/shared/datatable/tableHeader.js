export default {
  template: `
    <div class="w-full grid items-center group gap-2 grid-cols-[auto_1.5rem]"
         :class="{'cursor-pointer': params.enableSorting}"
         :data-e2e="'e2e-CO-TableHeader-' + params.column.colId "
         @click="onSortRequested((activeSort == 'asc' ? 'desc' : 'asc'), $event)">
      <div v-if="params.html" class="customHeaderLabel truncate" v-html="params.html"></div>
      <div v-else class="customHeaderLabel truncate">{{ params.displayName }}</div>
      <div v-if="activeSort == 'asc'" class="customSortDownLabel text-sn-black">
        <i class="sn-icon sn-icon-sort-up"></i>
      </div>
      <div v-if="activeSort == 'desc'" class="customSortUpLabel text-sn-black">
        <i class="sn-icon sn-icon-sort-down"></i>
      </div>
      <div v-if="activeSort == null && params.enableSorting" class="text-sn-black tw-hidden group-hover:block">
        <i class="sn-icon sn-icon-sort"></i>
      </div>
    </div>
  `,
  data() {
    return {
      activeSort: null
    };
  },
  beforeMount() {},
  mounted() {
    this.params.column.addEventListener('sortChanged', this.onSortChanged);
    this.onSortChanged();
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

    onSortRequested(order, event) {
      if (!this.params.enableSorting) return;

      this.params.setSort(order, event.shiftKey);
    }
  }
};
