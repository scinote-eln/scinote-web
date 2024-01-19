<template>
  <div class="asset uploading-attachment-container"
       :class="`${attachmentViewMode} ${attachment.error ? 'error' : ''}`"
  >
    <div class="icon">
      <i v-if="!attachment.error" class="fas fa-file"></i>
      <i v-if="attachment.error" class="fas fa-exclamation-triangle"></i>
    </div>
    <div class="file-name" :class="{'one-line': attachmentViewMode == 'list-attachment-container' }">
      <div v-if="!attachment.error">{{ i18n.t("attachments.new.uploading") }}</div>
      <div class="file-name-text">{{ attachment.attributes.file_name }}</div>
    </div>
    <div v-if="!attachment.error" class="progress-container">
      <div class="progress-bar" :style="`width: ${attachment.attributes.progress}%`"></div>
    </div>
    <div v-if="attachment.error" class="error-container">
      {{ attachment.error }}
    </div>
    <div v-if="attachment.error" class="remove-button" @click="$emit('attachment:delete')">
      <i class="sn-icon sn-icon-close"></i>
    </div>
  </div>
</template>
<script>
export default {
  name: 'uploadingAttachment',
  props: {
    attachment: {
      type: Object,
      required: true
    },
    parentId: {
      type: Number,
      required: true
    }
  },
  computed: {
    attachmentViewMode() {
      switch (this.attachment.attributes.view_mode) {
        case 'inline':
          return 'inline-attachment-container';
        case 'list':
          return 'list-attachment-container';
        default:
          return 'attachment-container';
      }
    }
  }
};
</script>
