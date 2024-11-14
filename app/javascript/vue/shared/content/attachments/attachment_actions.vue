<template>
  <div class="flex items-center gap-1.5 justify-end w-[184px]">
    <OpenMenu
      :attachment="attachment"
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
      @attachment:versionRestored="$emit('attachment:versionRestored', $event)"
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
  }
};
</script>
