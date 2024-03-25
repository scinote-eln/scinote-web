<template>
  <div class="content__attachments pr-8" :id='"content__attachments-" + parent.id'>
    <div class="sci-divider my-6"></div>
    <div class="content__attachments-actions">
      <div class="title">
        {{ i18n.t('protocols.steps.files', {count: attachments.length}) }}
      </div>
      <div class="flex items-center gap-2" v-if="parent.attributes.attachments_manageble && attachmentsReady">
        <MenuDropdown
          :listItems="this.viewModeMenu"
          :btnText="i18n.t('attachments.preview_menu')"
          :position="'right'"
          :caret="true"
          @attachment:viewMode = "changeAttachmentsViewMode"
        ></MenuDropdown>
        <MenuDropdown
          :listItems="this.sortMenu"
          :btnIcon="'sn-icon sn-icon-sort-down'"
          :btnClasses="'btn btn-light icon-btn'"
          :position="'right'"
          @attachment:order = "changeAttachmentsOrder"
        ></MenuDropdown>
      </div>
    </div>
    <div class="attachments" :data-parent-id="parent.id">
      <component
        v-for="(attachment, index) in attachmentsOrdered"
        :key="attachment.id"
        :is="attachment_view_mode(attachmentsOrdered[index])"
        :attachment="attachment"
        :parentId="parseInt(parent.id)"
        @attachment:viewMode="updateAttachmentViewMode"
        @attachment:delete="deleteAttachment(attachment.id)"
        @attachment:moved="attachmentMoved"
        @attachment:uploaded="$emit('attachment:uploaded')"
        @attachment:changed="$emit('attachment:changed', $event)"
      />
    </div>
  </div>
</template>
<script>
import AttachmentMovedMixin from './attachments/mixins/attachment_moved.js';
import listAttachment from './attachments/list.vue';
import inlineAttachment from './attachments/inline.vue';
import thumbnailAttachment from './attachments/thumbnail.vue';
import uploadingAttachment from './attachments/uploading.vue';
import emptyAttachment from './attachments/empty.vue';
import MenuDropdown from '../menu_dropdown.vue';

import WopiFileModal from './attachments/mixins/wopi_file_modal.js';

export default {
  name: 'Attachments',
  props: {
    attachments: {
      type: Array,
      required: true
    },
    parent: {
      type: Object,
      required: true
    },
    attachmentsReady: {
      type: Boolean,
      required: true
    }
  },
  data() {
    return {
      viewModeOptions: ['inline', 'thumbnail', 'list'],
      orderOptions: ['new', 'old', 'atoz', 'ztoa']
    };
  },
  mixins: [WopiFileModal, AttachmentMovedMixin],
  components: {
    thumbnailAttachment,
    inlineAttachment,
    listAttachment,
    uploadingAttachment,
    emptyAttachment,
    MenuDropdown
  },
  watch: {
    attachmentsReady() {
      if (this.attachmentsReady) {
        this.$nextTick(() => {
          this.initMarvinJS();
        });
      }
    }
  },
  computed: {
    attachmentsOrdered() {
      if (this.attachments.some((attachment) => attachment.attributes.uploading)) {
        return this.attachments;
      }
      return this.attachments.sort((a, b) => {
        if (a.attributes.asset_order == b.attributes.asset_order) {
          switch (this.parent.attributes.assets_order) {
            case 'new':
              return b.attributes.updated_at - a.attributes.updated_at;
            case 'old':
              return a.attributes.updated_at - b.attributes.updated_at;
            case 'atoz':
              return a.attributes.file_name.toLowerCase() > b.attributes.file_name.toLowerCase() ? 1 : -1;
            case 'ztoa':
              return b.attributes.file_name.toLowerCase() > a.attributes.file_name.toLowerCase() ? 1 : -1;
          }
        }

        return a.attributes.asset_order > b.attributes.asset_order ? 1 : -1;
      });
    },
    viewModeMenu() {
      const menu = [];
      this.viewModeOptions.forEach((viewMode) => {
        menu.push({
          active: this.parent.attributes.assets_view_mode == viewMode,
          text: this.i18n.t(`attachments.view_mode.${viewMode}_html`),
          emit: 'attachment:viewMode',
          params: viewMode
        });
      });
      return menu;
    },
    sortMenu() {
      const menu = [];
      this.orderOptions.forEach((orderOption) => {
        menu.push({
          text: this.i18n.t(`general.sort_new.${orderOption}`),
          emit: 'attachment:order',
          params: orderOption,
          active: this.parent.attributes.assets_order === orderOption
        });
      });
      return menu;
    }
  },
  mounted() {
    this.initMarvinJS();
    $(this.$refs.actionsDropdownButton).on('shown.bs.dropdown hidden.bs.dropdown', this.handleDropdownPosition);
  },
  methods: {
    changeAttachmentsOrder(order) {
      this.$emit('attachments:order', order);
    },
    changeAttachmentsViewMode(viewMode) {
      this.$emit('attachments:viewMode', viewMode);
    },
    updateAttachmentViewMode(id, viewMode) {
      this.$emit('attachment:viewMode', id, viewMode);
    },
    attachment_view_mode(attachment) {
      if (attachment.attributes.uploading) {
        return 'uploadingAttachment';
      } if (!attachment.attributes.attached) {
        return 'emptyAttachment';
      }
      return `${attachment.attributes.view_mode}Attachment`;
    },
    deleteAttachment(id) {
      this.$emit('attachment:deleted', id);
    },
    initMarvinJS() {
      // legacy logic from app/assets/javascripts/sitewide/marvinjs_editor.js
      MarvinJsEditor.initNewButton(
        `#content__attachments-${this.parent.id} .new-marvinjs-upload-button`,
        () => this.$emit('attachment:uploaded')
      );
    },
    handleDropdownPosition() {
      this.$refs.actionsDropdownButton.classList.toggle('dropup', !this.isInViewport(this.$refs.actionsDropdown));
    },
    isInViewport(el) {
      const rect = el.getBoundingClientRect();

      return (
        rect.top >= 0
              && rect.left >= 0
              && rect.bottom <= (window.innerHeight || $(window).height())
              && rect.right <= (window.innerWidth || $(window).width())
      );
    }
  }
};
</script>
