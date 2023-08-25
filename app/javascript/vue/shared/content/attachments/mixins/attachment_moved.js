export default {
  methods: {
    attachmentMoved(attachmentId, targetId) {
      this.$emit('attachment:moved', attachmentId, targetId);
    }
  }
};
