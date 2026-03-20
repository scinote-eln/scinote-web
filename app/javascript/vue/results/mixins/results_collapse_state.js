export default {
  data() {
    return {
      resultsCollapsed: false
    };
  },
  methods: {
    checkResultsState() {
      this.resultsCollapsed = this.$refs.results.every((result) => result.isCollapsed);
    },
    collapseResults() {
      $('.result-wrapper .collapse').collapse('hide');
      this.updateResultStateSettings(true);
      this.$refs.results.forEach((result) => { result.isCollapsed = true; });
      this.resultsCollapsed = true;
    },
    expandResults() {
      $('.result-wrapper .collapse').collapse('show');
      this.updateResultStateSettings(false);
      this.$refs.results.forEach((result) => { result.isCollapsed = false; });
      this.resultsCollapsed = false;
    },
    updateResultStateSettings(newState) {
      const data = {};

      if (newState) {
        data.collapsed = true;
      } else {
        data.expanded = true;
      }

      axios.post(this.changeStatesUrl, data);
    }
  }
};
