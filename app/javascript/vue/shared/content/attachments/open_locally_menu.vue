<template>
  <div class="sn-open-locally-menu" @mouseenter="fetchLocalAppInfo">
    <div v-if="!canOpenLocally && (attachment.attributes.wopi && attachment.attributes.urls.edit_asset)">
      <a v-if="editWopiEnabled" :href="`${attachment.attributes.urls.edit_asset}`" target="_blank"
      class="block whitespace-nowrap rounded px-3 py-2.5
              hover:!text-sn-blue hover:no-underline cursor-pointer hover:bg-sn-super-light-grey">
          {{ attachment.attributes.wopi_context.button_text }}
      </a>
      <button class="btn btn-light" v-else style="pointer-events: all;"
        :title="attachment.attributes.wopi_context.title" disabled="true">
        {{ attachment.attributes.wopi_context.button_text }}
      </button>
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

    <Teleport to="body">
      <NoPredefinedAppModal
        v-if="showNoPredefinedAppModal"
        :fileName="attachment.attributes.file_name"
        @close="showNoPredefinedAppModal = false"
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
    </Teleport>
  </div>
</template>

<script>
import OpenLocallyMixin from './mixins/open_locally.js';
import MenuDropdown from '../../menu_dropdown.vue';
import UpdateVersionModal from '../modal/update_version_modal.vue';

export default {
  name: 'OpenLocallyMenu',
  mixins: [OpenLocallyMixin],
  components: { MenuDropdown, UpdateVersionModal },
  props: {
    attachment: { type: Object, required: true },
    disableLocalOpen: { type: Boolean, default: false }
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
          url: this.attachment.attributes.urls.edit_asset,
          url_target: '_blank'
        });
      }

      if (this.attachment.attributes.image_editable) {
        menu.push({
          text: this.i18n.t('assets.file_preview.edit_in_scinote'),
          emit: 'openImageEditor'
        });
      }

      if (this.canOpenLocally && !this.disableLocalOpen) {
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
    editWopiEnabled() {
      return this.attachment.attributes.wopi_context.edit_supported;
    }
  },
  methods: {
    openImageEditor() {
      document.getElementById('editImageButton').click();
    }
  }
};
</script>
