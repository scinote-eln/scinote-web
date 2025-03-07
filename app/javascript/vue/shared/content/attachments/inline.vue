<template>
  <div
    class="inline-attachment-container asset"
    :class="[{'menu-dropdown-open': isMenuDropdownOpen}, {'context-menu-open': isContextMenuOpen }]"
    :data-e2e="`e2e-CO-${dataE2e}-attachment${attachment.id}-inline`"
    ref="inlineAttachmentContainer"
    :data-asset-id="attachment.id"
  >
    <div class="header justify-between">
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
            {{ attachment.attributes.updated_at_formatted }}
          </span>
          <span>
            {{ attachment.attributes.file_size_formatted }}
          </span>
        </div>
      </div>
      <div class="flex items-center ml-auto gap-2">
        <AttachmentActions
          :attachment="attachment"
          @attachment:viewMode="updateViewMode"
          @attachment:delete="deleteAttachment"
          @attachment:moved="attachmentMoved"
          @attachment:uploaded="reloadAttachments"
          @attachment:versionRestored="reloadAttachments"
          @attachment:changed="$emit('attachment:changed', $event)"
          @attachment:update="$emit('attachment:update', $event)"
          @attachment:toggle_menu="toggleMenuDropdown"
          @attachment:move_modal="showMoveModal"
          @attachment:open="$emit($event)"
        />
      </div>
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
    <Teleport to="body">
      <MoveAssetModal
        v-if="movingAttachment"
        :parent_type="attachment.attributes.parent_type"
        :targets_url="attachment.attributes.urls.move_targets"
        @confirm="moveAttachment($event)" @cancel="closeMoveModal"
      />
    </Teleport>
  </div>

</template>

<script>
import AttachmentMovedMixin from './mixins/attachment_moved.js';
import ContextMenuMixin from './mixins/context_menu.js';
import ContextMenu from './context_menu.vue';
import PdfViewer from '../../pdf_viewer.vue';
import MoveAssetModal from '../modal/move.vue';
import MoveMixin from './mixins/move.js';
import OpenLocallyMixin from './mixins/open_locally.js';
import AttachmentActions from './attachment_actions.vue';
import OpenMenu from './open_menu.vue';

export default {
  name: 'inlineAttachment',
  mixins: [ContextMenuMixin, AttachmentMovedMixin, MoveMixin, OpenLocallyMixin],
  components: {
    ContextMenu,
    PdfViewer,
    MoveAssetModal,
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
      showWopi: false,
      isMenuDropdownOpen: false,
      isContextMenuOpen: false
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
    },
    toggleContextMenu(isOpen) {
      this.isContextMenuOpen = isOpen;
    },
    toggleMenuDropdown(isOpen) {
      this.isMenuDropdownOpen = isOpen;
    }
  },
};
</script>
