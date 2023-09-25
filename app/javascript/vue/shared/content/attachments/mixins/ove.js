export default {
  mounted() {
    this.initOVE();
  },
  computed: {
    OVEurl() {
      if (this.step) {
        return this.step.attributes.open_vector_editor_context.new_sequence_asset_url;
      } else if (this.result) {
        return this.result.attributes.open_vector_editor_context.new_sequence_asset_url;
      }
    }
  },
  methods: {
    openOVEditor() {
      window.showIFrameModal(this.OVEurl);
    },
    initOVE() {
      $(window.iFrameModal).on('sequenceSaved', () => {
        this.loadAttachments();
      });
    },
  }
};
