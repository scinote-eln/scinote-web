<template>
  <div class="sn-open-locally-menu">
    <div v-if="!this.canOpenLocally && (this.attachment.wopi && this.attachment.urls.edit_asset)">
        <a :href="`${this.attachment.urls.edit_asset}`" target="_blank"
        class="block whitespace-nowrap rounded px-3 py-2.5
               hover:!text-sn-blue hover:no-underline cursor-pointer hover:bg-sn-super-light-grey">
            {{ this.attachment.wopi_context.button_text }}
        </a>
    </div>
    <div v-else>
        <MenuDropdown
          class="ml-auto"
          :listItems="this.menu"
          :btnClasses="`btn btn-light icon-btn !bg-sn-white`"
          :position="'right'"
          :btnText="'Open in'"
          @open_locally="openLocally"
        ></MenuDropdown>
    </div>
  </div>
</template>

<script>
import OpenLocallyMixin from './mixins/open_locally.js';
import MenuDropdown from '../../menu_dropdown.vue';

export default {
  name: 'OpenLocallyMenu',
  mixins: [OpenLocallyMixin],
  components: { MenuDropdown },
  props: {
    data: { type: String, required: true },
  },
  created() {
    window.openLocallyMenu = this;
    this.attachment = JSON.parse(this.data);
  },
  beforeUnmount() {
    delete window.openLocallyMenuComponent;
  },
  computed: {
    menu() {
      const menu = [];

      if (this.attachment.wopi && this.attachment.urls.edit_asset) {
        menu.push({
          text: this.attachment.wopi_context.button_text,
          url: this.attachment.urls.edit_asset,
          url_target: '_blank',
        });
      }
      if (this.canOpenLocally) {
        const text = this.localAppName
          ? this.i18n.t('attachments.open_locally_in', { application: this.localAppName })
          : this.i18n.t('attachments.open_locally');

        menu.push({
          text,
          emit: 'open_locally',
        });
      }

      return menu;
    },
  },
};
</script>
