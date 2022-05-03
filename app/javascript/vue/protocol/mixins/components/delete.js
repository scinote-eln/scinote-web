export default {
  methods: {
    showDeleteModal() {
      $('#modalDestroyProtocolContent').modal('show');
      $('#modalDestroyProtocolContent .delete-step').off().one('click', () => {
        this.deleteComponent();
        $('#modalDestroyProtocolContent').modal('hide');
      });
    },
    deleteComponent() {
      $.ajax({
        url: this.element.attributes.element.urls.delete_url,
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
