import axios from '../../../../packs/custom_axios';

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
    deleteElement() {
      axios.delete(this.deleteUrl || this.element.urls.delete_url)
        .then((result) => {
          this.$emit(
            'component:delete',
            { id: this.element.id, orderable_type: this.element.orderable_type }
          );
        });
    }
  }
};
