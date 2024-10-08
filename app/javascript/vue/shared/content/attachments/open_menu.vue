<template>
  <span>
    <!-- multiple options -->
    <MenuDropdown
      v-if="multipleOpenOptions.length > 1"
      :listItems="multipleOpenOptions"
      :btnClasses="'btn btn-light icon-btn thumbnail-action-btn'"
      :position="'left'"
      :btnIcon="'sn-icon sn-icon-open'"
      :title="i18n.t('attachments.thumbnail.buttons.open')"
      @menu-toggle="toggleMenu"
      @open_locally="openLocally"
      @open_scinote_editor="openScinoteEditor"
    >
    </MenuDropdown>

    <!-- open locally -->
    <a
      class="btn btn-light icon-btn thumbnail-action-btn"
      v-else-if="canOpenLocally"
      @click="openLocally"
      :title="i18n.t('attachments.thumbnail.buttons.open')"
    >
      <i class="sn-icon sn-icon-open"></i>
    </a>

    <!-- wopi -->
    <a
      class="btn btn-light icon-btn thumbnail-action-btn"
      v-else-if="this.attachment.attributes.wopi && this.attachment.attributes.urls.edit_asset"
      :href="attachment.attributes.urls.edit_asset"
      :title="i18n.t('attachments.thumbnail.buttons.open')"
      id="wopi_file_edit_button"
      :class="attachment.attributes.wopi_context.edit_supported ? '' : 'disabled'"
      target="_blank"
    >
      <i class="sn-icon sn-icon-open"></i>
    </a>

    <!-- gene sequence -->
    <a
      class="btn btn-light icon-btn thumbnail-action-btn ove-edit-button"
      v-else-if="attachment.attributes.asset_type == 'gene_sequence' && attachment.attributes.urls.open_vector_editor_edit"
      @click="openOVEditor(attachment.attributes.urls.open_vector_editor_edit)"
    >
      <i class="sn-icon sn-icon-open"></i>
    </a>

    <!-- marvin js -->
    <a
      class="btn btn-light icon-btn thumbnail-action-btn marvinjs-edit-button"
      v-else-if="attachment.attributes.asset_type == 'marvinjs' && attachment.attributes.urls.marvin_js_start_edit"
      :data-sketch-id="attachment.id"
      :data-update-url="attachment.attributes.urls.marvin_js"
      :data-sketch-start-edit-url="attachment.attributes.urls.marvin_js_start_edit"
      :data-sketch-name="attachment.attributes.metadata.name"
      :data-sketch-description="attachment.attributes.metadata.description"
    >
      <i class="sn-icon sn-icon-open"></i>
    </a>

    <!-- editing -->
    <a
      class="btn btn-light icon-btn thumbnail-action-btn image-edit-button"
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

    <!-- hidden -->
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
    <Teleport to="body">
      <NoPredefinedAppModal
        v-if="showNoPredefinedAppModal"
        :fileName="attachment.attributes.file_name"
        @close="showNoPredefinedAppModal = false"
      />
      <RestrictedExtensionModal
        v-if="showRestrictedExtensionModal"
        @close="showRestrictedExtensionModal = false"
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
  </span>
</template>

<script>
import OpenLocallyMixin from './mixins/open_locally.js';
import MenuDropdown from '../../../shared/menu_dropdown.vue';

export default {
  name: 'multipleOpen',
  mixins: [OpenLocallyMixin],
  emits: ['menu-dropdown-toggle'],
  components: {
    MenuDropdown
  },
  props: {
    attachment: {
      type: Object,
      required: true
    }
  },
  mounted() {
    this.fetchLocalAppInfo();
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
  methods: {
    toggleMenu(isOpen) {
      this.$emit('menu-dropdown-toggle', isOpen);
    },
    openScinoteEditor() {
      this.$refs.imageEditButton.click();
    },
    openOVEditor(url) {
      window.showIFrameModal(url);
    }
  }
};

</script>
