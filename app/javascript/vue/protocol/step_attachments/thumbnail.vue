<template>
  <div class="attachment-container asset"
       :data-asset-id="attachment.id"
  >
    <a  :href="attachment.attributes.urls.blob"
        class="file-preview-link file-name"
        :id="`modal_link${attachment.id}`"
        data-no-turbolink="true"
        :data-id="attachment.id"
        :data-gallery-view-id="stepId"
        :data-preview-url="attachment.attributes.urls.preview"
    >
      <div class="attachment-preview <%= asset.file.attached? ? asset.file.metadata['asset_type'] : '' %>">
        <img v-if="attachment.medium_preview"
            :src="attachment.medium_preview"
            :onerror='ActiveStoragePreviews.reCheckPreview(event)'
            :onload='ActiveStoragePreviews.showPreview(event)'
            style='opacity: 0' />
        <i  v-else class="fas" :class="attachment.attributes.icon"></i>
      </div>
      <div class="attachment-label">
        {{ attachment.attributes.file_name }}
      </div>
      <div class="attachment-metadata">
        {{ i18n.t('assets.placeholder.modified_label') }} {{ attachment.attributes.updated_at }}<br>
        {{ attachment.attributes.file_size }}
      </div>
    </a>
  </div>

</template>

<script>
  export default {
    name: 'thumbnailAttachment',
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
