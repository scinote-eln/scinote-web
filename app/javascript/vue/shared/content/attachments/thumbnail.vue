<template>
  <div class="attachment-container asset"
       :data-asset-id="attachment.id"
       @mouseenter="handleMouseEnter"
       @mouseleave="handleMouseLeave"
       v-click-outside="handleClickOutsideThumbnail"
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
        <div class="truncate overflow-hidden whitespace-break-spaces line-clamp-6 text-sn-blue">
          {{ attachment.attributes.file_name }}
        </div>
      </a>
      <div class="absolute bottom-16">
        <div class="text-sn-grey">
          {{ attachment.attributes.updated_at_formatted }}
        </div>
        <div class="text-sn-grey">
          {{ attachment.attributes.file_size_formatted }}
        </div>
      </div>

      <div class="absolute bottom-4 w-[184px] grid grid-cols-[repeat(4,_2.5rem)] justify-between">

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
          v-show="showOptions"
          :attachment="attachment"
          @attachment:viewMode="updateViewMode"
          @attachment:delete="deleteAttachment"
          @attachment:moved="attachmentMoved"
          @attachment:uploaded="reloadAttachments"
          @attachment:update="$emit('attachment:update', $event)"
          @menu-toggle="toggleMenu"
          :withBorder="true"
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
      <NoPredefinedAppModal
        v-if="showNoPredefinedAppModal"
        :fileName="attachment.attributes.file_name"
        @close="showNoPredefinedAppModal = false"
      />
      <UpdateVersionModal
        v-if="showUpdateVersionModal"
        @close="showUpdateVersionModal = false"
      />
      <editLaunchingApplicationModal
        v-if="editAppModal"
        :fileName="attachment.attributes.file_name"
        :application="this.localAppName"
        @close="editAppModal = false"
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
import MoveAssetModal from '../modal/move.vue';
import MoveMixin from './mixins/move.js';
import OpenLocallyMixin from './mixins/open_locally.js';
import OpenMenu from './open_menu.vue';
import { vOnClickOutside } from '@vueuse/components';

export default {
  name: 'thumbnailAttachment',
  mixins: [ContextMenuMixin, AttachmentMovedMixin, MoveMixin, OpenLocallyMixin],
  components: {
    ContextMenu,
    deleteAttachmentModal,
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
      showOptions: false,
      deleteModal: false,
      isMenuOpen: false
    };
  },
  directives: {
    'click-outside': vOnClickOutside
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
      await this.fetchLocalAppInfo();
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
