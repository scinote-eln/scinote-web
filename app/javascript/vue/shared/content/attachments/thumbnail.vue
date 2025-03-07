<template>
  <div class="attachment-container asset"
       :data-asset-id="attachment.id"
       @mouseenter="handleMouseEnter"
       @mouseleave="handleMouseLeave"
       v-click-outside="handleClickOutsideThumbnail"
       :data-e2e="`e2e-CO-${dataE2e}-attachment${attachment.id}-thumbnail`"
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
        class="file-preview-link file-name max-h-36 overflow-auto"
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
      <div class="absolute bottom-4">
        <AttachmentActions
          :withBorder="true"
          :attachment="attachment"
          :showOptions="showOptions"
          @attachment:viewMode="updateViewMode"
          @attachment:delete="deleteAttachment"
          @attachment:moved="attachmentMoved"
          @attachment:uploaded="reloadAttachments"
          @attachment:versionRestored="reloadAttachments"
          @attachment:changed="$emit('attachment:changed', $event)"
          @attachment:update="$emit('attachment:update', $event)"
          @attachment:toggle_menu="toggleMenu"
          @attachment:move_modal="showMoveModal"
          @attachment:open="$emit($event)"
        />
      </div>
    </div>
    <Teleport to="body">
      <deleteAttachmentModal
        v-if="deleteModal"
        :fileName="attachment.attributes.file_name"
        @confirm="deleteAttachment"
        @cancel="deleteModal = false"
      />
      <MoveAssetModal
        v-if="movingAttachment"
        :parent_type="attachment.attributes.parent_type"
        :targets_url="attachment.attributes.urls.move_targets"
        @confirm="moveAttachment($event)" @cancel="closeMoveModal"
      />
    </Teleport>
    <a  class="image-edit-button hidden"
      v-if="attachment.attributes.asset_type != 'marvinjs'
            && attachment.attributes.image_editable
            && attachment.attributes.urls.start_edit_image"
      ref="imageEditButton"
      :data-image-id="attachment.id"
      :data-image-name="attachment.attributes.file_name"
      :data-image-url="attachment.attributes.urls.asset_file"
      :data-image-quality="attachment.attributes.image_context.quality"
      :data-image-mime-type="attachment.attributes.image_context.type"
      :data-image-start-edit-url="attachment.attributes.urls.start_edit_image"
    ></a>
  </div>
</template>

<script>
import AttachmentMovedMixin from './mixins/attachment_moved.js';
import ContextMenuMixin from './mixins/context_menu.js';
import ContextMenu from './context_menu.vue';
import deleteAttachmentModal from './delete_modal.vue';
import MenuDropdown from '../../../shared/menu_dropdown.vue';
import MoveAssetModal from '../modal/move.vue';
import MoveMixin from './mixins/move.js';
import OpenMenu from './open_menu.vue';
import AttachmentActions from './attachment_actions.vue';
import { vOnClickOutside } from '@vueuse/components';

export default {
  name: 'thumbnailAttachment',
  mixins: [ContextMenuMixin, AttachmentMovedMixin, MoveMixin],
  components: {
    ContextMenu,
    deleteAttachmentModal,
    MoveAssetModal,
    MenuDropdown,
    OpenMenu,
    AttachmentActions
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
      showOptions: false,
      deleteModal: false,
      isMenuOpen: false
    };
  },
  directives: {
    'click-outside': vOnClickOutside
  },
  mounted() {
    $(this.$nextTick(() => {
      $('.attachment-preview img')
        .on('error', (event) => ActiveStoragePreviews.reCheckPreview(event))
        .on('load', (event) => ActiveStoragePreviews.showPreview(event));
    }));
  },
  watch: {
    showOptions(newValue) {
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
    openScinoteEditor() {
      this.$refs.imageEditButton.click();
    },
    handleMouseLeave() {
      if (!this.isMenuOpen) {
        this.showOptions = false;
      }
    },
    async handleMouseEnter() {
      this.showOptions = true;
    },
    toggleMenu(isMenuOpen) {
      this.isMenuOpen = isMenuOpen;
      if (isMenuOpen) {
        this.showOptions = true;
      }
    },
    handleClickOutsideThumbnail(event) {
      const isClickInsideModal = event.target.closest('.modal');
      if (!isClickInsideModal) {
        this.showOptions = false;
        this.isMenuOpen = false;
      }
    },
  }
};
</script>
