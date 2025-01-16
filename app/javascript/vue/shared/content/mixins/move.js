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
    moveElement(targetId) {
      axios.post(this.moveUrl || this.element.attributes.orderable.urls.move_url, { target_id: targetId })
        .then(() => {
          this.movingElement = false;
          this.$emit('moved', this.element.attributes.position, targetId);
        });
    }
  }
};
