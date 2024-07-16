<template>
  <div class="flex items-center gap-1.5 justify-end w-[184px]">
    <OpenMenu
      :attachment="attachment"
      :multipleOpenOptions="multipleOpenOptions"
      @open="$emit('attachment:toggle_menu', $event)"
      @close="$emit('attachment:toggle_menu', $event)"
      @menu-dropdown-toggle="$emit('attachment:toggle_menu', $event)"
      @option:click="$emit('attachment:open', $event)"
    />
    <a v-if="attachment.attributes.urls.move"
      @click.prevent.stop="$emit('attachment:move_modal')"
      class="btn btn-light icon-btn thumbnail-action-btn"
      :title="i18n.t('attachments.thumbnail.buttons.move')">
      <i class="sn-icon sn-icon-move"></i>
    </a>
    <a class="btn btn-light icon-btn thumbnail-action-btn"
      :title="i18n.t('attachments.thumbnail.buttons.download')"
      :href="attachment.attributes.urls.download" data-turbolinks="false">
      <i class="sn-icon sn-icon-export"></i>
    </a>
    <ContextMenu
      :attachment="attachment"
      @attachment:viewMode="$emit('attachment:viewMode', $event)"
      @attachment:delete="$emit('attachment:delete', $event)"
      @attachment:moved="$emit('attachment:moved', $event)"
      @attachment:uploaded="$emit('attachment:uploaded', $event)"
      @attachment:changed="$emit('attachment:changed', $event)"
      @attachment:update="$emit('attachment:update', $event)"
      @menu-toggle="$emit('attachment:toggle_menu', $event)"
      :withBorder="withBorder"
    />
  </div>
</template>

<script>
import OpenLocallyMixin from './mixins/open_locally.js';
import OpenMenu from './open_menu.vue';
import ContextMenu from './context_menu.vue';

export default {
  name: 'attachmentActions',
  props: {
    attachment: Object,
    withBorder: false
  },
  mixins: [OpenLocallyMixin],
  components: {
    OpenMenu,
    ContextMenu
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
  }
};
</script>
