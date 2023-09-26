import axios from '../../../../packs/custom_axios.js';

export default {
  data() {
    return {
      movingElement: false
    };
  },
  methods: {
    showMoveModal() {
      this.movingElement = true;
    },
    closeMoveModal() {
      this.movingElement = false;
    },
    moveElement(target_id) {
      axios.post(this.element.attributes.orderable.urls.move_url, { target_id: target_id }).
        then(() => {
          this.movingElement = false;
          this.$emit('moved', this.element.attributes.position, target_id);
        });
    }
  }
};
