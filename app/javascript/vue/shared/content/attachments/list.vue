<template>
  <div class="list-attachment-container asset hover:bg-sn-super-light-grey"
    :class="[{'menu-dropdown-open': isMenuDropdownOpen}, {'context-menu-open': isContextMenuOpen }]"
    :data-asset-id="attachment.id">
      <div id="icon-with-filename" class="h-6 my-auto">
        <i class="text-sn-grey asset-icon sn-icon mb-1" :class="attachment.attributes.icon"></i>
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
      </div>

      <div id="file-metadata" class="file-metadata">
        <span class="my-auto">
            {{ attachment.attributes.updated_at_formatted }}
        </span>
        <span class="my-auto">
          {{ attachment.attributes.file_size_formatted }}
        </span>
      </div>

      <div class="flex flex-row" id="action-buttons">

        <!-- open -->
        <OpenMenu
          :attachment="attachment"
          :multipleOpenOptions="multipleOpenOptions"
          @menu-dropdown-toggle="toggleMenuDropdown"
          >
        </OpenMenu>

        <!-- move -->
        <a v-if="attachment.attributes.urls.move"
          @click.prevent.stop="showMoveModal"
          class="btn btn-light icon-btn thumbnail-action-btn"
          :title="i18n.t('attachments.thumbnail.buttons.move')">
          <i class="sn-icon sn-icon-move"></i>
        </a>

        <!-- download -->
        <a class="btn btn-light icon-btn thumbnail-action-btn"
          :title="i18n.t('attachments.thumbnail.buttons.download')"
          :href="attachment.attributes.urls.download" data-turbolinks="false">
          <i class="sn-icon sn-icon-export"></i>
        </a>

        <!-- more options -->
        <ContextMenu
          :attachment="attachment"
          @attachment:viewMode="updateViewMode"
          @attachment:delete="deleteAttachment"
          @attachment:moved="attachmentMoved"
          @attachment:uploaded="reloadAttachments"
          @menu-toggle="toggleContextMenu"
          @attachment:update="$emit('attachment:update', $event)"
        />
      </div>
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
import OpenLocallyMixin from './mixins/open_locally.js';
import MoveAssetModal from '../modal/move.vue';
import OpenMenu from './open_menu.vue';

export default {
  name: 'listAttachment',
  mixins: [ContextMenuMixin, AttachmentMovedMixin, MoveMixin, OpenLocallyMixin],
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
