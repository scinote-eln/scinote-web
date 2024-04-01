export default {
  computed: {
    cardSelected() {
      const item = window.dtComponent.selectedRows.find((i) => (i.code === this.params.code));

      return !!item;
    }
  },
  methods: {
    itemSelected() {
      const item = window.dtComponent.selectedRows.find((i) => (i.code === this.params.code));

      if (item) {
        window.dtComponent.selectedRows = window.dtComponent.selectedRows
          .filter((i) => (i.code !== this.params.code));
      } else {
        window.dtComponent.selectedRows.push(this.params);
      }
    },
  },
};
