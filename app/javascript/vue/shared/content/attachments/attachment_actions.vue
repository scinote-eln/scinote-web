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
    <button v-if="attachment.attributes.urls.restore"
      @click.prevent.stop="$emit('attachment:restore', attachment.id)"
      class="btn btn-light icon-btn thumbnail-action-btn"
      :title="i18n.t('attachments.thumbnail.buttons.restore')">
      <i class="sn-icon sn-icon-restore"></i>
    </button>
    <a class="btn btn-light icon-btn thumbnail-action-btn"
      :title="i18n.t('attachments.thumbnail.buttons.download')"
      :href="attachment.attributes.urls.download" data-turbolinks="false">
      <i class="sn-icon sn-icon-export"></i>
    </a>
    <button class="btn btn-light icon-btn thumbnail-action-btn"
      :title="i18n.t('attachments.thumbnail.buttons.delete')"
      @click.prevent.stop="deleteModal=true"
      v-if="this.attachment.attributes.urls.delete && this.attachment.attributes.archived">
      <i class="sn-icon sn-icon-delete"></i>
    </button>
    <ContextMenu
      :attachment="attachment"
      @attachment:viewMode="$emit('attachment:viewMode', $event)"
      @attachment:archive="$emit('attachment:archive', $event)"
      @attachment:delete="$emit('attachment:delete', $event)"
      @attachment:moved="$emit('attachment:moved', $event)"
      @attachment:uploaded="$emit('attachment:uploaded', $event)"
      @attachment:changed="$emit('attachment:changed', $event)"
      @attachment:update="$emit('attachment:update', $event)"
      @menu-toggle="$emit('attachment:toggle_menu', $event)"
      @attachment:versionRestored="$emit('attachment:versionRestored', $event)"
      :withBorder="withBorder"
    />
    <teleport to="body">
      <deleteAttachmentModal
        v-if="deleteModal"
        :fileName="attachment.attributes.file_name"
        @confirm="deleteAttachment"
        @cancel="deleteModal = false"
      />
    </teleport>
  </div>
</template>

<script>
import OpenLocallyMixin from './mixins/open_locally.js';
import OpenMenu from './open_menu.vue';
import ContextMenu from './context_menu.vue';
import deleteAttachmentModal from './delete_modal.vue';

export default {
  name: 'attachmentActions',
  props: {
    attachment: Object,
    withBorder: false
  },
  mixins: [OpenLocallyMixin],
  data() {
    return {
      deleteModal: false
    };
  },
  components: {
    OpenMenu,
    ContextMenu,
    deleteAttachmentModal
  },
  methods: {
    deleteAttachment() {
      this.deleteModal = false;
      this.$emit('attachment:delete', this.attachment.id);
    }
  }
};
</script>
