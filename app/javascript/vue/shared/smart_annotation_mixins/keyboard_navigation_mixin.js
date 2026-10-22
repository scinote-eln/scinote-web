export default {
  data() {
    return {
      activeIndex: -1
    };
  },
  computed: {
    navigableItems() {
      return this.showPills ? this.pills : (this.items || []);
    }
  },
  methods: {
    resetActiveIndex() {
      this.activeIndex = this.navigableItems.length > 0 ? 0 : -1;
    },
    isActiveIndex(index) {
      return index === this.activeIndex;
    },
    moveActiveIndex(delta) {
      const length = this.navigableItems.length;
      if (length === 0) return;

      this.activeIndex = (this.activeIndex + delta + length) % length;
    },
    selectActiveItem() {
      const item = this.navigableItems[this.activeIndex];
      if (!item) return;

      if (this.showPills) {
        this.openPill(item);
      } else {
        this.rowClick(item);
      }
    },
    handleNavigationKeydown(e) {
      if (e.key === 'ArrowDown') {
        e.preventDefault();
        this.moveActiveIndex(1);
      } else if (e.key === 'ArrowUp') {
        e.preventDefault();
        this.moveActiveIndex(-1);
      } else if (e.key === 'Enter') {
        e.preventDefault();
        this.selectActiveItem();
      }
    }
  }
};
