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
          :data-gallery-view-id="parentId"
          :data-preview-url="attachment.attributes.urls.preview"
        >
          <span data-toggle="tooltip"
               data-placement="bottom"
               :title="`${ attachment.attributes.file_name }`">
            {{ attachment.attributes.file_name }}
          </span>
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
      <ContextMenu
        :attachment="attachment"
        @attachment:viewMode="updateViewMode"
        @attachment:delete="deleteAttachment"
        @attachment:moved="attachmentMoved"
        @attachment:uploaded="reloadAttachments"
      />
    </div>
    <template v-if="attachment.attributes.wopi">
      <div v-if="showWopi"
           class="iframe-placeholder"
           :data-iframe-url="attachment.attributes.urls.wopi_action"></div>
      <div v-else class="empty-office-file">
        <h2>{{ i18n.t('assets.empty_office_file.description') }}</h2>
        <a :href="attachment.attributes.urls.load_asset"
           class="btn btn-primary reload-asset"
           @click.prevent="reloadAsset">
          {{ i18n.t('assets.empty_office_file.reload') }}
        </a>
      </div>
    </template>
    <template v-else-if="attachment.attributes.pdf_previewable && attachment.attributes.pdf !== null">
      <PdfViewer :pdf="attachment.attributes.pdf" />
    </template>
    <template v-else-if="attachment.attributes.large_preview !== null">
      <div class="image-container">
        <img :src="attachment.attributes.large_preview"
             style='opacity: 0' />
      </div>
    </template>
    <template v-else>
      <div class="general-file-container">
        <i class="text-sn-grey sn-icon" :class="attachment.attributes.icon"></i>
      </div>
    </template>
  </div>

</template>

<script>
import AttachmentMovedMixin from './mixins/attachment_moved.js';
import ContextMenuMixin from './mixins/context_menu.js';
import ContextMenu from './context_menu.vue';
import PdfViewer from '../../pdf_viewer.vue';

export default {
  name: 'inlineAttachment',
  mixins: [ContextMenuMixin, AttachmentMovedMixin],
  components: { ContextMenu, PdfViewer },
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
  data() {
    return {
      showWopi: false
    };
  },
  mounted() {
    this.showWopi = this.attachment.attributes.file_size > 0;
    $(this.$nextTick(() => {
      $('.image-container img')
        .on('error', (event) => ActiveStoragePreviews.reCheckPreview(event))
        .on('load', (event) => ActiveStoragePreviews.showPreview(event));
    }));
  },
  methods: {
    reloadAsset() {
      $.ajax({
        method: 'GET',
        url: this.attachment.attributes.urls.load_asset,
        data: {
          asset: { view_mode: this.attachment.attributes.view_mode }
        },
        success: (data) => {
          if (!(data.html.includes('empty-office-file'))) {
            this.showWopi = true;
          }
        }
      });
    }
  }
};
</script>
