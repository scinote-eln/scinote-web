import axios from '../../../../packs/custom_axios.js';

export default {
  methods: {
    archiveElement() {
      axios.post(this.archiveUrl || this.element.attributes.orderable.urls.archive_url)
        .then((result) => {
          this.$emit(
            'component:archive',
            this.element.id
          );
        });
    },
    restoreElement() {
      axios.post(this.restoreUrl || this.element.attributes.orderable.urls.restore_url)
        .then((result) => {
          this.$emit(
            'component:restore',
            this.element.id
          );
        });
    }
  }
};
