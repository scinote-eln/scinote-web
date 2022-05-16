<template>
  <div class="list-attachment-container asset"
       :data-asset-id="attachment.id"
  >
    <i class="fas asset-icon" :class="attachment.attributes.icon"></i>
    <a :href="attachment.attributes.urls.blob"
       class="file-preview-link file-name"
       :id="`modal_link${attachment.id}`"
       data-no-turbolink="true"
       :data-id="attachment.id"
       :data-gallery-view-id="stepId"
       :data-preview-url="attachment.attributes.urls.preview"
    >
      {{ attachment.attributes.file_name }}
    </a>
    <div class="file-metadata">
      <span>
          {{ i18n.t('assets.placeholder.modified_label') }}
          {{ attachment.attributes.updated_at_formatted }}
      </span>
      <span>
        {{ i18n.t('assets.placeholder.size_label', {size: attachment.attributes.file_size_formatted}) }}
      </span>
    </div>
  </div>
</template>

<script>
  export default {
    name: 'listAttachment',
    props: {
      attachment: {
        type: Object,
        required: true
      },
      stepId: {
        type: Number,
        required: true
      }
    },
  }
</script>
