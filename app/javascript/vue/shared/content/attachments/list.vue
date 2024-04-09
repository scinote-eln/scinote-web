<template>
  <div class="list-attachment-container asset"
       :data-asset-id="attachment.id"
  >
    <i class="text-sn-grey asset-icon sn-icon" :class="attachment.attributes.icon"></i>
    <a :href="attachment.attributes.urls.blob"
       class="file-preview-link file-name"
       :id="`modal_link${attachment.id}`"
       data-no-turbolink="true"
       :data-id="attachment.id"
       :data-gallery-view-id="parentId"
       :data-preview-url="attachment.attributes.urls.preview"
    >
      <span class="attachment-name" data-toggle="tooltip"
           data-placement="bottom">
        {{ attachment.attributes.file_name }}
      </span>
    </a>
    <div v-if="attachment.attributes.medium_preview !== null" class="attachment-image-tooltip bg-white sn-shadow-menu-sm">
      <img :src="this.imageLoadError ? attachment.attributes.urls.blob : attachment.attributes.medium_preview" @error="ActiveStoragePreviews.reCheckPreview"
            @load="ActiveStoragePreviews.showPreview"/>
    </div>
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
      v-if="!externalProcessing"
      :attachment="attachment"
      @attachment:viewMode="updateViewMode"
      @attachment:delete="deleteAttachment"
      @attachment:moved="attachmentMoved"
      @attachment:uploaded="reloadAttachments"
    />
  </div>
</template>

<script>
import AttachmentMovedMixin from './mixins/attachment_moved.js';
import ContextMenuMixin from './mixins/context_menu.js';
import ContextMenu from './context_menu.vue';
import axios from '../../../../packs/custom_axios.js';

export default {
  name: 'listAttachment',
  mixins: [ContextMenuMixin, AttachmentMovedMixin],
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
  watch: {
    externalProcessing() {
      if (this.externalProcessing) {
        this.checkProcessing();
      }
    }
  },
  data() {
    return {
      externalProcessing: false,
      imageLoadError: false
    };
  },
  mounted() {
    this.externalProcessing = this.attachment.attributes.external_processing;
  },
  methods: {
    handleImageError() {
      this.imageLoadError = true;
    },
    checkProcessing() {
      axios.get(this.attachment.attributes.urls.show)
        .then((response) => {
          this.externalProcessing = response.data.data.attributes.external_processing;
          if (this.externalProcessing) {
            setTimeout(() => {
              this.checkProcessing();
            }, 5000);
          }
        });
    }
  }
};
</script>
