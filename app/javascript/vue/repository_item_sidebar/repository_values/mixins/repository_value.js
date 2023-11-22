export default {
  props: {
    colId: Number,
    colVal: String,
    inArchivedRepository: Boolean,
  },
  data() {
    return {
      editing: false,
    };
  },
  methods: {
    update(newValue) {
      const repositoryCells = {};
      repositoryCells[this.colId] = newValue;
      this.$emit('update', { repository_cells: repositoryCells });
    },
  },
};
