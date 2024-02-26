export default {
  methods: {
    itemSelected() {
      const item = this.dtComponent.selectedRows.find((i) => (i.id === this.params.id));

      if (item) {
        this.dtComponent.selectedRows = this.dtComponent.selectedRows
          .filter((i) => (i.id !== this.params.id));
      } else {
        this.dtComponent.selectedRows.push(this.params);
      }
    },
  },
};
