export default {
  data() {
    return {
      confirmingDelete: false
    };
  },
  methods: {
    showDeleteModal() {
      this.confirmingDelete = true;
    },
    closeDeleteModal() {
      this.confirmingDelete = false;
    },
    deleteComponent() {
      $.ajax({
        url: this.element.attributes.orderable.urls.delete_url,
        type: 'DELETE',
        success: (result) => {
          this.$emit(
            'component:delete',
            result.data
          );
        }
      });
    }
  }
};
