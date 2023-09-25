<template>
  <div class="attachment-container asset"
       :data-asset-id="attachment.id"
       @mouseover="isHovered = true"
       @mouseleave="isHovered = false"
  >
    <a  :class="{ hidden: isHovered }"
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
            class="rounded-sm"
            :src="attachment.attributes.medium_preview"
            style='opacity: 0' />
        <div v-else class="w-[186px] h-[186px] bg-sn-super-light-grey rounded-sm"></div>
      </div>
      <div class="attachment-label"
           data-toggle="tooltip"
           data-placement="bottom"
           :title="`${ attachment.attributes.file_name }`">
        {{ attachment.attributes.file_name }}
      </div>
    </a>
    <div :class="{ hidden: !isHovered }" class="hovered-thumbnail h-full">
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
      <div class="absolute bottom-16 text-sn-grey">
        {{ attachment.attributes.file_size_formatted }}
      </div>
      <div class="absolute bottom-4 min-w-[194px] justify-between flex">
        <a class="btn btn-light icon-btn thumbnail-action-btn image-edit-button"
          v-if="attachment.attributes.urls.edit_asset"
          :title="i18n.t('attachments.thumbnail.buttons.edit')"
          :data-image-id="attachment.id"
          :data-image-name="attachment.attributes.file_name"
          :data-image-url="attachment.attributes.urls.asset_file"
          :data-image-quality="attachment.attributes.image_context && attachment.attributes.image_context.quality"
          :data-image-mime-type="attachment.attributes.image_context && attachment.attributes.image_context.type"
          :data-image-start-edit-url="attachment.attributes.urls.start_edit_image"
        >
          <i class="sn-icon sn-icon-edit"></i>
        </a>
        <a v-if="attachment.attributes.urls.move" @click.prevent.stop="showMoveModal" class="btn btn-light icon-btn thumbnail-action-btn" :title="i18n.t('attachments.thumbnail.buttons.move')">
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
      v-if="isHovered"
      :attachment="attachment"
      @attachment:viewMode="updateViewMode"
      @attachment:delete="deleteAttachment"
      @attachment:moved="attachmentMoved"
      :withBorder="true"
    />
    <deleteAttachmentModal
      v-if="deleteModal"
      :fileName="attachment.attributes.file_name"
      @confirm="deleteAttachment"
      @cancel="deleteModal = false"
    />
    <moveAssetModal v-if="movingAttachment"
                      :parent_type="attachment.attributes.parent_type"
                      :targets_url="attachment.attributes.urls.move_targets"
                      @confirm="moveAttachment($event)" @cancel="closeMoveModal"/>
  </div>

</template>

<script>
  import AttachmentMovedMixin from './mixins/attachment_moved.js'
  import ContextMenuMixin from './mixins/context_menu.js'
  import ContextMenu from './context_menu.vue'
  import deleteAttachmentModal from './delete_modal.vue'
  import MoveAssetModal from '../modal/move.vue'
  import MoveMixin from './mixins/move.js'

  export default {
    name: 'thumbnailAttachment',
    mixins: [ContextMenuMixin, AttachmentMovedMixin, MoveMixin],
    components: { ContextMenu, deleteAttachmentModal, MoveAssetModal},
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
    mounted() {
      $(this.$nextTick(function() {
        $(`.attachment-preview img`)
          .on('error', (event) => ActiveStoragePreviews.reCheckPreview(event))
          .on('load', (event) => ActiveStoragePreviews.showPreview(event))
      }))
    },
    watch: {
      isHovered: function(newValue) {
        // reload thumbnail on mouse out
        if(newValue) return;

        $(this.$nextTick(function() {
          $(`.attachment-preview img`)
            .on('error', (event) => ActiveStoragePreviews.reCheckPreview(event))
            .on('load', (event) => ActiveStoragePreviews.showPreview(event))
        }))
      }
    }
  }
</script>
