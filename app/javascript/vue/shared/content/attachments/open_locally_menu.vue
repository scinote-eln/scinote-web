<template>
  <div class="sn-open-locally-menu" @mouseenter="fetchLocalAppInfo">
    <div v-if="!canOpenLocally && (attachment.attributes.wopi && attachment.attributes.urls.edit_asset)">
      <a :href="`${attachment.attributes.urls.edit_asset}`" target="_blank"
      class="block whitespace-nowrap rounded px-3 py-2.5
              hover:!text-sn-blue hover:no-underline cursor-pointer hover:bg-sn-super-light-grey">
          {{ attachment.attributes.wopi_context.button_text }}
      </a>
    </div>
    <div v-else>
      <MenuDropdown
        v-if="menu.length > 1"
        class="ml-auto"
        :listItems="menu"
        :btnClasses="`btn btn-light icon-btn !bg-sn-white`"
        :position="'right'"
        :btnText="i18n.t('attachments.open_in')"
        :caret="true"
        @open-locally="openLocally"
        @open-scinote-editor="openImageEditor"
      ></MenuDropdown>
      <a v-else-if="menu.length === 1" class="btn btn-light !bg-sn-white" :href="menu[0].url" :target="menu[0].target" @click="this[this.menu[0].emit]()">
        {{ menu[0].text }}
      </a>
      <Teleport to="body">
        <UpdateVersionModal
          v-if="showUpdateVersionModal"
          @cancel="showUpdateVersionModal = false"
        />
      </Teleport>
    </div>
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
  data: {
    showUpdateVersionModal: false
  },
  props: {
    attachment: { type: Object, required: true }
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
          emit: 'openScinoteEditor'
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
  },
  methods: {
    openImageEditor() {
      document.getElementById('editImageButton').click();
    }
  }
};
</script>
