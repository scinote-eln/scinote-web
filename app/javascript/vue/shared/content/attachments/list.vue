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
       :data-gallery-view-id="parentId"
       :data-preview-url="attachment.attributes.urls.preview"
    >
      <span data-toggle="tooltip"
           data-placement="bottom"
           :title="`${ attachment.attributes.file_name }`">
        {{ attachment.attributes.file_name }}
      </span>
    </a>
    <span v-if="attachment.isNewUpload" class="attachment-label-new">
      {{ i18n.t('protocols.steps.attachments.new.description') }}
    </span>
    <div class="file-metadata">
      <span>
          {{ i18n.t('assets.placeholder.modified_label') }}
          {{ attachment.attributes.updated_at_formatted }}
      </span>
      <span>
        {{ i18n.t('assets.placeholder.size_label', {size: attachment.attributes.file_size_formatted}) }}
      </span>
    </div>
    <ContextMenu
      :attachment="attachment"
      @attachment:viewMode="updateViewMode"
      @attachment:delete="deleteAttachment"
    />
  </div>
</template>

<script>
  import ContextMenuMixin from './mixins/context_menu.js'
  import ContextMenu from './context_menu.vue'

  export default {
    name: 'listAttachment',
    mixins: [ContextMenuMixin],
    components: { ContextMenu },
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
  }
</script>
