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
      <div v-if="attachment.attributes.medium_preview" class="attachment-preview" :class= "attachment.attributes.asset_type">
        <img
            :src="attachment.attributes.medium_preview"
            @error="ActiveStoragePreviews.reCheckPreview"
            @load="ActiveStoragePreviews.showPreview"
            style='opacity: 0' />
      </div>
      <div v-else class="attachment-preview flex">
        <span class="fa fa-paperclip m-auto text-4xl"></span>
      </div>
      <div class="attachment-label"
           data-toggle="tooltip"
           data-placement="bottom"
           :title="`${ attachment.attributes.file_name }`">
        {{ attachment.attributes.file_name }}
        <span v-if="attachment.isNewUpload" class="attachment-label-new">
          {{ i18n.t('protocols.steps.attachments.new.description') }}
        </span>
      </div>
      <div class="attachment-metadata">
        {{ i18n.t('assets.placeholder.modified_label') }} {{ attachment.attributes.updated_at_formatted }}<br>
        {{ attachment.attributes.file_size_formatted }}
      </div>
    </a>
    <ContextMenu
      :attachment="attachment"
      @attachment:viewMode="updateViewMode"
      @attachment:delete="deleteAttachment"
    />
  </div>

</template>

<script>
import ContextMenuMixin from './mixins/context_menu.js';
import ContextMenu from './context_menu.vue';

export default {
  name: 'thumbnailAttachment',
  mixins: [ContextMenuMixin],
  components: { ContextMenu },
  props: {
    attachment: {
      type: Object,
      required: true
    },
    stepId: {
      type: Number,
      required: true
    }
  }
};
</script>
