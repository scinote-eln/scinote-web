<template>
  <div class="asset-context-menu"
       ref="menu"
  >
    <a  class="marvinjs-edit-button hidden"
        v-if="attachment.attributes.asset_type == 'marvinjs' && attachment.attributes.urls.marvin_js_start_edit"
        ref="marvinjsEditButton"
        :data-sketch-id="attachment.id"
        :data-update-url="attachment.attributes.urls.marvin_js"
        :data-sketch-start-edit-url="attachment.attributes.urls.marvin_js_start_edit"
        :data-sketch-name="attachment.attributes.metadata.name"
        :data-sketch-description="attachment.attributes.metadata.description"
    ></a>
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
    <MenuDropdown
      class="ml-auto"
      :listItems="this.menu"
      :btnClasses="`btn icon-btn bg-sn-white ${ withBorder ? 'btn-secondary' : 'btn-light'}`"
      :position="'right'"
      :btnIcon="'sn-icon sn-icon-more-hori'"
      @delete="deleteModal = true"
      @rename="renameModal = true"
      @duplicate="duplicate"
      @viewMode="changeViewMode"
      @move="showMoveModal"
      @fileVersionsModal="fileVersionsModal = true"
      @menu-toggle="$emit('menu-toggle', $event)"
    ></MenuDropdown>
    <Teleport to="body">
      <RenameAttachmentModal
        v-if="renameModal"
        :attachment="attachment"
        @attachment:update="$emit('attachment:update', $event)"
        @close="renameModal = false"
      />
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
      <FileVersionsModal
        v-if="fileVersionsModal"
        :versionsUrl="attachment.attributes.urls.versions"
        :restoreVersionUrl="attachment.attributes.urls.restore_version"
        @close="fileVersionsModal = false"
        @fileVersionRestored="$emit('attachment:versionRestored', $event)"
      />
    </Teleport>
  </div>
</template>

<script>
import RenameAttachmentModal from '../modal/rename_modal.vue';
import deleteAttachmentModal from './delete_modal.vue';
import MoveAssetModal from '../modal/move.vue';
import MoveMixin from './mixins/move.js';
import MenuDropdown from '../../menu_dropdown.vue';
import FileVersionsModal from '../../file_versions_modal.vue';
import axios from '../../../../packs/custom_axios.js';

export default {
  name: 'contextMenu',
  components: {
    RenameAttachmentModal,
    deleteAttachmentModal,
    MoveAssetModal,
    FileVersionsModal,
    MenuDropdown
  },
  mixins: [MoveMixin],
  props: {
    attachment: {
      type: Object,
      required: true
    },
    withBorder: { default: false, type: Boolean },
    displayInDropdown: {
      type: Array,
      default: []
    }
  },
  data() {
    return {
      viewModeOptions: ['inline', 'thumbnail', 'list'],
      deleteModal: false,
      renameModal: false,
      fileVersionsModal: false
    };
  },
  computed: {
    menu() {
      const menu = [];
      if (this.displayInDropdown.includes('download')) {
        menu.push({
          text: this.i18n.t('Download'),
          url: this.attachment.attributes.urls.download,
          url_target: '_blank',
          data_e2e: 'e2e-BT-attachmentOptions-download'
        });
      }
      if (this.attachment.attributes.urls.duplicate) {
        menu.push({
          text: this.i18n.t('assets.context_menu.duplicate'),
          emit: 'duplicate'
        });
      }
      if (this.attachment.attributes.urls.rename) {
        menu.push({
          text: this.i18n.t('assets.context_menu.rename'),
          emit: 'rename'
        });
      }
      if (this.attachment.attributes.urls.delete) {
        menu.push({
          text: this.i18n.t('assets.context_menu.delete'),
          emit: 'delete',
          data_e2e: 'e2e-BT-attachmentOptions-delete'
        });
      }
      if (this.attachment.attributes.urls.versions) {
        menu.push({
          text: this.i18n.t('assets.context_menu.versions'),
          emit: 'fileVersionsModal'
        });
      }
      if (this.attachment.attributes.urls.toggle_view_mode) {
        this.viewModeOptions.forEach((viewMode, i) => {
          menu.push({
            active: this.attachment.attributes.view_mode === viewMode,
            text: this.i18n.t(`assets.context_menu.${viewMode}_html`),
            emit: 'viewMode',
            params: viewMode,
            data_e2e: `e2e-BT-attachmentOptions-${viewMode}`,
            dividerBefore: i === 0
          });
        });
      }
      return menu;
    }
  },
  methods: {
    changeViewMode(viewMode) {
      this.$emit('attachment:viewMode', viewMode);
      $.ajax({
        url: this.attachment.attributes.urls.toggle_view_mode,
        type: 'PATCH',
        dataType: 'json',
        data: { asset: { view_mode: viewMode } }
      });
    },
    duplicate() {
      axios.post(this.attachment.attributes.urls.duplicate).then(() => {
        this.reloadAttachments();
      }).catch((e) => {
        console.error(e);
      });
    },
    deleteAttachment() {
      this.deleteModal = false;
      this.$emit('attachment:delete');
    },
    openOVEditor(url) {
      window.showIFrameModal(url);
    },
    reloadAttachments() {
      this.$emit('attachment:uploaded');
    }
  }
};
</script>
