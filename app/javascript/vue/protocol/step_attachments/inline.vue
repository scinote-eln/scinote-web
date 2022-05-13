<template>
  <div class="inline-attachment-container asset"
       :data-asset-id="attachment.id"
  >
    <div class="header">
      <div class="file-info">
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
            {{ attachment.attributes.updated_at }}
          </span>
          <span>
            {{ i18n.t('assets.placeholder.size_label', {size: attachment.attributes.file_size_formatted}) }}
          </span>
        </div>
      </div>
    </div>
    <template v-if="attachment.attributes.wopi">
      <div v-if="attachment.attributes.file_size > 0"
           class="iframe-placeholder"
           :data-iframe-url="attachment.attributes.urls.wopi_action"></div>
      <div v-else class="empty-office-file">
        <h2>{{ i18n.t('assets.empty_office_file.description') }}</h2>
        <a :href="attachment.attributes.urls.load_asset"
           remote="true"
           class="btn btn-primary reload-asset"
           :params="{asset: {view_mode: attachment.attributes.view_mode}}">
          {{ i18n.t('assets.empty_office_file.reload') }}
        </a>
      </div>
    </template>
    <template v-else-if="attachment.attributes.pdf_previewable">
    </template>
    <template v-else-if="attachment.attributes.large_preview !== null">
      <div class="image-container">
        <img :src="attachment.attributes_large_preview"
             @error="ActiveStoragePreviews.reCheckPreview"
             @load="ActiveStoragePreviews.showPreview"
             style='opacity: 0' />
      </div>
    </template>
    <template v-else>
      <div class="general-file-container">
        <i lass="fas" :class="attachment.attributes.icon"></i>
      </div>
    </template>
  </div>

</template>

<script>
  export default {
    name: 'inlineAttachment',
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
