export default {
  computed: {
    cardSelected() {
      const item = this.dtComponent.selectedRows.find((i) => (i.code === this.params.code));

      return !!item;
    }
  },
  methods: {
    itemSelected() {
      const item = this.dtComponent.selectedRows.find((i) => (i.code === this.params.code));

      if (item) {
        this.dtComponent.selectedRows = this.dtComponent.selectedRows
          .filter((i) => (i.code !== this.params.code));
      } else {
        this.dtComponent.selectedRows.push(this.params);
      }
    },
  },
};
