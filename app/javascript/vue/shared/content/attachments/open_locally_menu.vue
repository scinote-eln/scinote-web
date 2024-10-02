<template>
  <div class="sn-open-locally-menu flex" @mouseenter="fetchLocalAppInfo">
    <div v-if="(!canOpenLocally) && (attachment.attributes.wopi && attachment.attributes.urls.edit_asset)">
      <a :href="editWopiSupported ? attachment.attributes.urls.edit_asset : null" target="_blank"
         class="btn btn-light"
         :class="{ 'disabled': !editWopiSupported }"
         :title="editWopiSupported ? null : attachment.attributes.wopi_context.title"
         style="pointer-events: all"
      >
          {{ attachment.attributes.wopi_context.button_text }}
      </a>
    </div>
    <div v-else-if="!usesWebIntegration">
        <MenuDropdown
          v-if="this.menu.length > 1"
          class="ml-auto"
          :listItems="this.menu"
          :btnClasses="`btn btn-light icon-btn`"
          :position="'right'"
          :btnText="i18n.t('attachments.open_in')"
          :caret="true"
          @open-locally="openLocally"
          @open-image-editor="openImageEditor"
        ></MenuDropdown>
        <a v-else-if="menu.length === 1" class="btn btn-light" :href="menu[0].url" :target="menu[0].url_target" @click="this[this.menu[0].emit]()">
          {{ menu[0].text }}
        </a>
    </div>
    <a @click="fileVersionsModal = true" class="btn btn-light"><i class="sn-icon sn-icon-history-search"></i>{{ i18n.t('assets.context_menu.versions') }}</a>

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
      <editLaunchingApplicationModal
        v-if="editAppModal"
        :fileName="attachment.attributes.file_name"
        :application="this.localAppName"
        @close="editAppModal = false"
      />
      <UpdateVersionModal
        v-if="showUpdateVersionModal"
        @close="showUpdateVersionModal = false"
      />
       <FileVersionsModal
        v-if="fileVersionsModal"
        :versionsUrl="attachment.attributes.urls.versions"
        :restoreVersionUrl="attachment.attributes.urls.restore_version"
        @close="fileVersionsModal = false"
        @fileVersionRestored="refreshPreview"
      />
    </Teleport>
  </div>
</template>

<script>
import OpenLocallyMixin from './mixins/open_locally.js';
import MenuDropdown from '../../menu_dropdown.vue';
import UpdateVersionModal from '../modal/update_version_modal.vue';
import FileVersionsModal from '../../file_versions_modal.vue';

export default {
  name: 'OpenLocallyMenu',
  mixins: [OpenLocallyMixin],
  components: { MenuDropdown, UpdateVersionModal, FileVersionsModal },
  props: {
    attachment: { type: Object, required: true }
  },
  data() {
    return {
      fileVersionsModal: false
    };
  },
  created() {
    this.fetchLocalAppInfo();
    window.openLocallyMenu = this;
  },
  beforeUnmount() {
    delete window.openLocallyMenuComponent;
  },
  computed: {
    menu() {
      const menu = [];

      if (this.attachment.attributes.wopi && this.attachment.attributes.urls.edit_asset) {
        menu.push({
          text: this.attachment.attributes.wopi_context.button_text,
          url: this.editWopiSupported ? this.attachment.attributes.urls.edit_asset : null,
          disabled: !this.editWopiSupported && 'style-only',
          title: this.editWopiSupported ? null : this.attachment.attributes.wopi_context.title,
          url_target: '_blank'
        });
      }

      if (this.attachment.attributes.image_editable) {
        menu.push({
          text: this.i18n.t('assets.file_preview.edit_in_scinote'),
          emit: 'openImageEditor'
        });
      }

      if (this.canOpenLocally) {
        const text = this.localAppName
          ? this.i18n.t('attachments.open_locally_in', { application: this.localAppName })
          : this.i18n.t('attachments.open_locally');

        menu.push({
          text,
          emit: 'openLocally'
        });
      }

      return menu;
    },
    usesWebIntegration() {
      return this.attachment.attributes.asset_type === 'gene_sequence'
        || this.attachment.attributes.asset_type === 'marvinjs';
    },
    editWopiSupported() {
      return this.attachment.attributes.wopi_context.edit_supported;
    }
  },
  methods: {
    openImageEditor() {
      document.getElementById('editImageButton').click();
    },
    refreshPreview() {
      const imageElement = document.querySelector('.file-preview-container .asset-image');

      if (!imageElement) return;

      window.ActiveStoragePreviews.reCheckPreview({ target: imageElement });
    }
  }
};
</script>
