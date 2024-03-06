<template>
  <div class="asset-context-menu"
       ref="menu"
       @mouseenter="fetchLocalAppInfo"
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
      :btnClasses="`btn btn-sm icon-btn !bg-sn-white ${ withBorder ? 'btn-secondary' : 'btn-light'}`"
      :position="'right'"
      :btnIcon="'sn-icon sn-icon-more-hori'"
      @open_ove_editor="openOVEditor(attachment.attributes.urls.open_vector_editor_edit)"
      @open_marvinjs_editor="openMarvinJsEditor"
      @open_scinote_editor="openScinoteEditor"
      @open_locally="openLocally"
      @delete="deleteModal = true"
      @viewMode="changeViewMode"
      @move="showMoveModal"
      @menu-visibility-changed="$emit('menu-visibility-changed', $event)"
    ></MenuDropdown>
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
  </div>
</template>

<script>
import deleteAttachmentModal from './delete_modal.vue';
import moveAssetModal from '../modal/move.vue';
import MoveMixin from './mixins/move.js';
import OpenLocallyMixin from './mixins/open_locally.js';
import MenuDropdown from '../../menu_dropdown.vue';

export default {
  name: 'contextMenu',
  components: {
    deleteAttachmentModal,
    moveAssetModal,
    MenuDropdown
  },
  mixins: [MoveMixin, OpenLocallyMixin],
  props: {
    attachment: {
      type: Object,
      required: true
    },
    withBorder: { default: false, type: Boolean }
  },
  data() {
    return {
      viewModeOptions: ['inline', 'thumbnail', 'list'],
      deleteModal: false
    };
  },
  computed: {
    menu() {
      const menu = [];
      if (this.attachment.attributes.wopi && this.attachment.attributes.urls.edit_asset) {
        menu.push({
          text: this.attachment.attributes.wopi_context.button_text,
          url: this.attachment.attributes.urls.edit_asset,
          url_target: '_blank'
        });
      }
      if (this.attachment.attributes.asset_type === 'gene_sequence' && this.attachment.attributes.urls.open_vector_editor_edit) {
        menu.push({
          text: this.i18n.t('open_vector_editor.edit_sequence'),
          emit: 'open_ove_editor'
        });
      }
      if (this.attachment.attributes.asset_type === 'marvinjs' && this.attachment.attributes.urls.marvin_js_start_edit) {
        menu.push({
          text: this.i18n.t('assets.file_preview.edit_in_marvinjs'),
          emit: 'open_marvinjs_editor'
        });
      }
      if (this.attachment.attributes.asset_type !== 'marvinjs'
          && this.attachment.attributes.image_editable
          && this.attachment.attributes.urls.start_edit_image) {
        menu.push({
          text: this.i18n.t('assets.file_preview.edit_in_scinote'),
          emit: 'open_scinote_editor'
        });
      }
      if (this.canOpenLocally) {
        const text = this.localAppName
          ? this.i18n.t('attachments.open_locally_in', { application: this.localAppName })
          : this.i18n.t('attachments.open_locally');

        menu.push({
          text,
          emit: 'open_locally',
          data_e2e: 'e2e-BT-attachmentOptions-openLocally'
        });
      }
      menu.push({
        text: this.i18n.t('Download'),
        url: this.attachment.attributes.urls.download,
        url_target: '_blank'
      });
      if (this.attachment.attributes.urls.move_targets) {
        menu.push({
          text: this.i18n.t('assets.context_menu.move'),
          emit: 'move'
        });
      }
      if (this.attachment.attributes.urls.delete) {
        menu.push({
          text: this.i18n.t('assets.context_menu.delete'),
          emit: 'delete'
        });
      }
      if (this.attachment.attributes.urls.toggle_view_mode) {
        this.viewModeOptions.forEach((viewMode, i) => {
          menu.push({
            active: this.attachment.attributes.view_mode === viewMode,
            text: this.i18n.t(`assets.context_menu.${viewMode}_html`),
            emit: 'viewMode',
            params: viewMode,
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
    deleteAttachment() {
      this.deleteModal = false;
      this.$emit('attachment:delete');
    },
    openOVEditor(url) {
      window.showIFrameModal(url);
    },
    reloadAttachments() {
      this.$emit('attachment:uploaded');
    },
    openMarvinJsEditor() {
      MarvinJsEditor.initNewButton(
        this.$refs.marvinjsEditButton,
        this.reloadAttachments
      );
      $(this.$refs.marvinjsEditButton).trigger('click');
    },
    openScinoteEditor() {
      $(this.$refs.imageEditButton).trigger('click');
    }
  }
};
</script>
