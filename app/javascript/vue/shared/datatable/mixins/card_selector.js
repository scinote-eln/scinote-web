export default {
  methods: {
    itemSelected() {
      let item = this.dtComponent.selectedRows.find((item) => {
        return item.id == this.params.id;
      });

      if (item) {
        this.dtComponent.selectedRows = this.dtComponent.selectedRows.filter((item) => {
          return item.id != this.params.id;
        });
      } else {
        this.dtComponent.selectedRows.push(this.params);
      }
    }
  }
}
