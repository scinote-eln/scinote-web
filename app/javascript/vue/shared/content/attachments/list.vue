<template>
  <div class="list-attachment-container asset"
       :data-asset-id="attachment.id"
       :data-e2e="`e2e-CO-${dataE2e}-attachment${attachment.id}-list`"
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
      :attachment="attachment"
      @attachment:viewMode="updateViewMode"
      @attachment:delete="deleteAttachment"
      @attachment:moved="attachmentMoved"
      @attachment:uploaded="reloadAttachments"
      @attachment:update="$emit('attachment:update', $event)"
    />
  </div>
  <Teleport to="body">
    <moveAssetModal
      v-if="movingAttachment"
      :parent_type="attachment.attributes.parent_type"
      :targets_url="attachment.attributes.urls.move_targets"
      @confirm="moveAttachment($event)" @cancel="closeMoveModal"
    />
  </Teleport>
</template>

<script>
import AttachmentMovedMixin from './mixins/attachment_moved.js';
import ContextMenuMixin from './mixins/context_menu.js';
import ContextMenu from './context_menu.vue';
import MoveMixin from './mixins/move.js';
import MoveAssetModal from '../modal/move.vue';
import OpenMenu from './open_menu.vue';

export default {
  name: 'listAttachment',
  mixins: [ContextMenuMixin, AttachmentMovedMixin, MoveMixin],
  components: {
    ContextMenu,
    MoveAssetModal,
    OpenMenu
  },
  props: {
    attachment: {
      type: Object,
      required: true
    },
    parentId: {
      type: Number,
      required: true
    },
    dataE2e: {
      type: String,
      default: ''
    }
  },
  data() {
    return {
      imageLoadError: false,
      isContextMenuOpen: false,
      isMenuDropdownOpen: false
    };
  },
  methods: {
    handleImageError() {
      this.imageLoadError = true;
    },
    toggleContextMenu(isOpen) {
      this.isContextMenuOpen = isOpen;
    },
    toggleMenuDropdown(isOpen) {
      this.isMenuDropdownOpen = isOpen;
    }
  },
  computed: {
    multipleOpenOptions() {
      const options = [];
      if (this.attachment.attributes.wopi && this.attachment.attributes.urls.edit_asset) {
        options.push({
          text: this.attachment.attributes.wopi_context.button_text,
          url: this.attachment.attributes.urls.edit_asset,
          url_target: '_blank'
        });
      }
      if (this.attachment.attributes.asset_type !== 'marvinjs'
          && this.attachment.attributes.image_editable
          && this.attachment.attributes.urls.start_edit_image) {
        options.push({
          text: this.i18n.t('assets.file_preview.edit_in_scinote'),
          emit: 'open_scinote_editor'
        });
      }
      if (this.canOpenLocally) {
        const text = this.localAppName
          ? this.i18n.t('attachments.open_locally_in', { application: this.localAppName })
          : this.i18n.t('attachments.open_locally');

        options.push({
          text,
          emit: 'open_locally',
          data_e2e: 'e2e-BT-attachmentOptions-openLocally'
        });
      }
      return options;
    }
  }
};
</script>
