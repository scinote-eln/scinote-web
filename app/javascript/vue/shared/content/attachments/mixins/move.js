import axios from '../../../../../packs/custom_axios.js';

export default {
  data() {
    return {
      movingAttachment: false
    };
  },
  methods: {
    showMoveModal() {
      this.movingAttachment = true;
    },
    closeMoveModal() {
      this.movingAttachment = false;
    },
    moveAttachment(targetId) {
      axios.post(this.attachment.attributes.urls.move, { target_id: targetId })
        .then(() => {
          this.movingAttachment = false;
          this.$emit('attachment:moved', this.attachment.id, targetId);
        });
    }
  }
};
