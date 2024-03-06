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
        {{ attachment.attributes.file_name }}
      </a>
      <div class="absolute bottom-16 text-sn-grey">
        {{ attachment.attributes.file_size_formatted }}
      </div>
      <div class="absolute bottom-4 w-[184px] grid grid-cols-[repeat(4,_2.5rem)] justify-between">
        <MenuDropdown
            v-if="multipleOpenOptions.length > 1"
            :listItems="multipleOpenOptions"
            :btnClasses="'btn btn-light icon-btn thumbnail-action-btn'"
            :position="'left'"
            :btnIcon="'sn-icon sn-icon-open'"
            :title="i18n.t('attachments.thumbnail.buttons.open')"
            @menu-visibility-changed="handleMenuVisibilityChange"
            @open_locally="openLocally"
            @open_scinote_editor="openScinoteEditor"
        ></MenuDropdown>
        <a class="btn btn-light icon-btn thumbnail-action-btn"
           v-else-if="canOpenLocally"
           @click="openLocally"
           :title="i18n.t('attachments.thumbnail.buttons.open')"
        >
          <i class="sn-icon sn-icon-open"></i>
        </a>
        <a class="btn btn-light icon-btn thumbnail-action-btn"
           v-else-if="this.attachment.attributes.wopi && this.attachment.attributes.urls.edit_asset"
           :href="attachment.attributes.urls.edit_asset"
           :title="i18n.t('attachments.thumbnail.buttons.open')"
           id="wopi_file_edit_button"
           :class="attachment.attributes.wopi_context.edit_supported ? '' : 'disabled'"
           target="_blank"
        >
          <i class="sn-icon sn-icon-open"></i>
        </a>
        <a class="btn btn-light icon-btn thumbnail-action-btn ove-edit-button"
           v-else-if="attachment.attributes.asset_type == 'gene_sequence' && attachment.attributes.urls.open_vector_editor_edit"
           @click="openOVEditor(attachment.attributes.urls.open_vector_editor_edit)"
        >
          <i class="sn-icon sn-icon-open"></i>
        </a>
        <a class="btn btn-light icon-btn thumbnail-action-btn marvinjs-edit-button"
           v-else-if="attachment.attributes.asset_type == 'marvinjs' && attachment.attributes.urls.marvin_js_start_edit"
           :data-sketch-id="attachment.id"
           :data-update-url="attachment.attributes.urls.marvin_js"
           :data-sketch-start-edit-url="attachment.attributes.urls.marvin_js_start_edit"
           :data-sketch-name="attachment.attributes.metadata.name"
           :data-sketch-description="attachment.attributes.metadata.description"
        >
          <i class="sn-icon sn-icon-open"></i>
        </a>
        <a class="btn btn-light icon-btn thumbnail-action-btn image-edit-button"
          v-else-if="attachment.attributes.image_editable && attachment.attributes.urls.edit_asset"
          :title="i18n.t('attachments.thumbnail.buttons.open')"
          :data-image-id="attachment.id"
          :data-image-name="attachment.attributes.file_name"
          :data-image-url="attachment.attributes.urls.asset_file"
          :data-image-quality="attachment.attributes.image_context && attachment.attributes.image_context.quality"
          :data-image-mime-type="attachment.attributes.image_context && attachment.attributes.image_context.type"
          :data-image-start-edit-url="attachment.attributes.urls.start_edit_image"
        >
          <i class="sn-icon sn-icon-open"></i>
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
      @attachment:changed="$emit('attachment:changed', $event)"
      @menu-visibility-changed="handleMenuVisibilityChange"
      :withBorder="true"
    />
    <Teleport to="body">
      <deleteAttachmentModal
        v-if="deleteModal"
        :fileName="attachment.attributes.file_name"
        @confirm="deleteAttachment"
        @cancel="deleteModal = false"
      />
      <moveAssetModal
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
import MenuDropdown from '../../../shared/menu_dropdown.vue';
import MoveAssetModal from '../modal/move.vue';
import MoveMixin from './mixins/move.js';
import OpenLocallyMixin from './mixins/open_locally.js';
import { vOnClickOutside } from '@vueuse/components';

export default {
  name: 'thumbnailAttachment',
  mixins: [ContextMenuMixin, AttachmentMovedMixin, MoveMixin, OpenLocallyMixin],
  components: {
    ContextMenu,
    deleteAttachmentModal,
    MoveAssetModal,
    MenuDropdown
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
    },
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
    handleMenuVisibilityChange(isMenuOpen) {
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
