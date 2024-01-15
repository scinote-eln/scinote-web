<template>
  <div class="attachment-container asset"
       :data-asset-id="attachment.id"
       @mouseover="showOptions = true"
       @mouseleave="handleMouseLeave"
  >
    <a  :class="{ hidden: showOptions }"
        :href="attachment.attributes.urls.blob"
        class="file-preview-link file-name"
        :id="`modal_link${attachment.id}`"
        data-no-turbolink="true"
        :data-id="attachment.id"
        :data-gallery-view-id="parentId"
        :data-preview-url="attachment.attributes.urls.preview"
        :data-e2e="`e2e-BT-attachment-${attachment.id}`"
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
    <div :class="{ hidden: !showOptions }" class="hovered-thumbnail h-full">
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
      <div class="absolute bottom-4 w-[184px] grid grid-cols-[repeat(4,_2.5rem)] justify-between">
        <a class="btn btn-light icon-btn thumbnail-action-btn"
           v-if="this.attachment.attributes.wopi && this.attachment.attributes.urls.edit_asset"
           :href="attachment.attributes.urls.edit_asset"
           id="wopi_file_edit_button"
           :class="attachment.attributes.wopi_context.edit_supported ? '' : 'disabled'"
           target="_blank"
        >
          <i class="sn-icon sn-icon-edit"></i>
        </a>
        <a class="btn btn-light icon-btn thumbnail-action-btn ove-edit-button"
           v-else-if="attachment.attributes.asset_type == 'gene_sequence' && attachment.attributes.urls.open_vector_editor_edit"
           @click="openOVEditor(attachment.attributes.urls.open_vector_editor_edit)"
        >
          <i class="sn-icon sn-icon-edit"></i>
        </a>
        <a class="btn btn-light icon-btn thumbnail-action-btn marvinjs-edit-button"
           v-else-if="attachment.attributes.asset_type == 'marvinjs' && attachment.attributes.urls.marvin_js_start_edit"
           :data-sketch-id="attachment.id"
           :data-update-url="attachment.attributes.urls.marvin_js"
           :data-sketch-start-edit-url="attachment.attributes.urls.marvin_js_start_edit"
           :data-sketch-name="attachment.attributes.metadata.name"
           :data-sketch-description="attachment.attributes.metadata.description"
        >
          <i class="sn-icon sn-icon-edit"></i>
        </a>
        <a class="btn btn-light icon-btn thumbnail-action-btn image-edit-button"
          v-else-if="attachment.attributes.image_editable && attachment.attributes.urls.edit_asset"
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
      v-show="showOptions"
      :attachment="attachment"
      @attachment:viewMode="updateViewMode"
      @attachment:delete="deleteAttachment"
      @attachment:moved="attachmentMoved"
      @attachment:uploaded="reloadAttachments"
      @menu-visibility-changed="handleMenuVisibilityChange"
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
import AttachmentMovedMixin from './mixins/attachment_moved.js';
import ContextMenuMixin from './mixins/context_menu.js';
import ContextMenu from './context_menu.vue';
import deleteAttachmentModal from './delete_modal.vue';
import MoveAssetModal from '../modal/move.vue';
import MoveMixin from './mixins/move.js';

export default {
  name: 'thumbnailAttachment',
  mixins: [ContextMenuMixin, AttachmentMovedMixin, MoveMixin],
  components: { ContextMenu, deleteAttachmentModal, MoveAssetModal },
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
      showOptions: false,
      isMenuOpen: false,
      deleteModal: false
    };
  },
  mounted() {
    $(this.$nextTick(() => {
      $('.attachment-preview img')
        .on('error', (event) => ActiveStoragePreviews.reCheckPreview(event))
        .on('load', (event) => ActiveStoragePreviews.showPreview(event));
    }));
  },
  watch: {
    isHovered(newValue) {
      // reload thumbnail on mouse out
      if (newValue) return;

      $(this.$nextTick(() => {
        $('.attachment-preview img')
          .on('error', (event) => ActiveStoragePreviews.reCheckPreview(event))
          .on('load', (event) => ActiveStoragePreviews.showPreview(event));
      }));
    }
  },
  methods: {
    openOVEditor(url) {
      window.showIFrameModal(url);
    },
    handleMouseLeave() {
      if (!this.isMenuOpen) {
        this.showOptions = false;
      }
    },
    handleMenuVisibilityChange(newValue) {
      this.isMenuOpen = newValue;
      this.showOptions = newValue;
    }
  }
};
</script>
