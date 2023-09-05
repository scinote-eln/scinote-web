<template>
  <div class="attachment-container asset"
       :data-asset-id="attachment.id"
       @mouseover="isHovered = true"
       @mouseleave="isHovered = false"
  >
    <a v-if="!isHovered"
        :href="attachment.attributes.urls.blob"
        class="file-preview-link file-name"
        :id="`modal_link${attachment.id}`"
        data-no-turbolink="true"
        :data-id="attachment.id"
        :data-gallery-view-id="parentId"
        :data-preview-url="attachment.attributes.urls.preview"
    >
      <div class="attachment-preview" :class= "attachment.attributes.asset_type">
        <img v-if="attachment.attributes.medium_preview !== null"
            :src="attachment.attributes.medium_preview"
            @error="ActiveStoragePreviews.reCheckPreview"
            @load="ActiveStoragePreviews.showPreview"
            style='opacity: 0' />
        <i  v-else class="fas" :class="attachment.attributes.icon"></i>
      </div>
      <div class="attachment-label"
           data-toggle="tooltip"
           data-placement="bottom"
           :title="`${ attachment.attributes.file_name }`">
        {{ attachment.attributes.file_name }}
        <span v-if="attachment.isNewUpload" class="attachment-label-new">
          {{ i18n.t('attachments.new.description') }}
        </span>
      </div>
    </a>
    <div v-else class="hovered-thumbnail">
      <a
        :href="attachment.attributes.urls.blob"
        class="file-preview-link file-name"
        :id="`modal_link${attachment.id}`"
        data-no-turbolink="true"
        :data-id="attachment.id"
        :data-gallery-view-id="parentId"
        :data-preview-url="attachment.attributes.urls.preview"
      >
        {{ attachment.attributes.file_name }}
      </a>
      <div class="absolute bottom-14 text-sn-grey">
        {{ attachment.attributes.file_size_formatted }}
      </div>
      <div class="absolute bottom-2 min-w-[194px] justify-between flex">
        <a class="btn btn-light icon-btn thumbnail-action-btn image-edit-button"
          :title="i18n.t('attachments.thumbnail.buttons.edit')"
          :data-image-id="attachment.id"
          :data-image-name="attachment.attributes.file_name"
          :data-image-url="attachment.attributes.urls.asset_file"
          :data-image-quality="attachment.attributes.image_context.quality"
          :data-image-mime-type="attachment.attributes.image_context.type"
          :data-image-start-edit-url="attachment.attributes.urls.start_edit_image"
        >
          <i class="sn-icon sn-icon-edit"></i>
        </a>
        <a class="btn btn-light icon-btn thumbnail-action-btn" :title="i18n.t('attachments.thumbnail.buttons.move')">
          <!-- TODO -->
          <i class="sn-icon sn-icon-move"></i>
        </a>
        <a class="btn btn-light icon-btn thumbnail-action-btn"
          :title="i18n.t('attachments.thumbnail.buttons.download')"
          :href="attachment.attributes.urls.download" data-turbolinks="false">
          <i class="sn-icon sn-icon-export"></i>
        </a>
        <template v-if="attachment.attributes.urls.delete">
          <a class="btn btn-light icon-btn thumbnail-action-btn"
            :title="i18n.t('attachments.thumbnail.buttons.delete')"
            @click.prevent.stop="deleteModal = true">
            <i class="sn-icon sn-icon-delete"></i>
          </a>
        </template>
      </div>
    </div>
    <ContextMenu
      :attachment="attachment"
      @attachment:viewMode="updateViewMode"
      @attachment:delete="deleteAttachment"
      @attachment:moved="attachmentMoved"
    />
    <deleteAttachmentModal
      v-if="deleteModal"
      :fileName="attachment.attributes.file_name"
      @confirm="deleteAttachment"
      @cancel="deleteModal = false"
    />
  </div>

</template>

<script>
  import AttachmentMovedMixin from './mixins/attachment_moved.js'
  import ContextMenuMixin from './mixins/context_menu.js'
  import ContextMenu from './context_menu.vue'
  import deleteAttachmentModal from './delete_modal.vue'

  export default {
    name: 'thumbnailAttachment',
    mixins: [ContextMenuMixin, AttachmentMovedMixin],
    components: { ContextMenu, deleteAttachmentModal },
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
        isHovered: false,
        deleteModal: false
      };
    },
    methods: {
      deleteAttachment() {
        this.deleteModal = false;
        this.$emit('attachment:delete');
      }
    }
  }
</script>
