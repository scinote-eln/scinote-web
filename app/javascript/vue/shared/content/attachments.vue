<template>
  <div class="content__attachments" :id='"content__attachments-" + parent.id'>
    <div class="content__attachments-actions">
      <div class="title">
        <h3>{{ i18n.t('protocols.steps.files', {count: attachments.length}) }}</h3>
      </div>
      <div class="flex items-center gap-2" v-if="parent.attributes.attachments_manageble && attachmentsReady">
        <div ref="actionsDropdownButton" class="dropdown sci-dropdown">
          <button class="btn btn-light dropdown-toggle" type="button" id="dropdownAttachmentsOptions" data-toggle="dropdown" aria-haspopup="true" aria-expanded="true">
            <span>{{ i18n.t("protocols.steps.attachments.preview_menu") }}</span>
            <span class="sn-icon sn-icon-down"></span>
          </button>
          <ul ref="actionsDropdown" class="dropdown-menu dropdown-menu-right dropdown-attachment-options"
              aria-labelledby="dropdownAttachmentsOptions"
              :data-parent-id="parent.id"
          >
            <template v-if="parent.attributes.urls.update_asset_view_mode_url">
              <li v-for="(viewMode, index) in viewModeOptions" :key="`viewMode_${index}`">
                <a
                  class="attachments-view-mode action-link"
                  :class="viewMode == parent.attributes.assets_view_mode ? 'selected' : ''"
                  @click="changeAttachmentsViewMode(viewMode)"
                  v-html="i18n.t(`protocols.steps.attachments.view_mode.${viewMode}_html`)"
                ></a>
              </li>
            </template>
          </ul>
        </div>
        <div ref="sortDropdownButton" class="dropdown sci-dropdown">
          <button class="btn btn-light icon-btn dropdown-toggle" type="button" id="dropdownSortAttachmentsOptions" data-toggle="dropdown" aria-haspopup="true" aria-expanded="true">
            <i class="sn-icon sn-icon-sort-up"></i>
          </button>
          <ul ref="sortDropdown" class="dropdown-menu dropdown-menu-right dropdown-attachment-options"
              aria-labelledby="dropdownSortAttachmentsOptions"
              :data-parent-id="parent.id"
          >
            <li v-for="(orderOption, index) in orderOptions" :key="`orderOption_${index}`" :class="{'divider' : (orderOption == 'divider')}">
              <a v-if="orderOption != 'divider'" class="action-link change-order"
                @click="changeAttachmentsOrder(orderOption)"
                :class="parent.attributes.assets_order == orderOption ? 'selected' : ''"
              >
                {{ i18n.t(`general.sort_new.${orderOption}`) }}
              </a>
            </li>
          </ul>
        </div>
      </div>
    </div>
    <div class="attachments" :data-parent-id="parent.id">
      <template v-for="(attachment, index) in attachmentsOrdered">
        <component
          :is="attachment_view_mode(attachmentsOrdered[index])"
          :key="attachment.id"
          :attachment="attachment"
          :parentId="parseInt(parent.id)"
          @attachment:viewMode="updateAttachmentViewMode"
          @attachment:delete="deleteAttachment(attachment.id)"
        />
      </template>
    </div>
  </div>
</template>
<script>
  import listAttachment from './attachments/list.vue'
  import inlineAttachment from './attachments/inline.vue'
  import thumbnailAttachment from './attachments/thumbnail.vue'
  import uploadingAttachment from './attachments/uploading.vue'
  import emptyAttachment from './attachments/empty.vue'

  import WopiFileModal from './attachments/mixins/wopi_file_modal.js'

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
        orderOptions: ['new', 'old', 'divider', 'atoz', 'ztoa']
      }
    },
    mixins: [WopiFileModal],
    components: {
      thumbnailAttachment,
      inlineAttachment,
      listAttachment,
      uploadingAttachment,
      emptyAttachment
    },
    computed: {
      attachmentsOrdered() {
        return this.attachments.sort((a, b) => {
          if (a.attributes.asset_order == b.attributes.asset_order) {
            switch(this.parent.attributes.assets_order) {
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
        })
      }
    },
    mounted() {
      this.initMarvinJS();
      $(this.$refs.actionsDropdownButton).on('shown.bs.dropdown hidden.bs.dropdown', this.handleDropdownPosition);
    },
    methods: {
      changeAttachmentsOrder(order) {
        this.$emit('attachments:order', order)
      },
      changeAttachmentsViewMode(viewMode) {
        this.$emit('attachments:viewMode', viewMode)
      },
      updateAttachmentViewMode(id, viewMode) {
        this.$emit('attachment:viewMode', id, viewMode)
      },
      attachment_view_mode(attachment) {
        if (attachment.attributes.uploading) {
          return 'uploadingAttachment'
        } else if (!attachment.attributes.attached) {
          return 'emptyAttachment'
        }
        return `${attachment.attributes.view_mode}Attachment`
      },
      deleteAttachment(id) {
        this.$emit('attachment:deleted', id)
      },
      initMarvinJS() {
        // legacy logic from app/assets/javascripts/sitewide/marvinjs_editor.js
        MarvinJsEditor.initNewButton(
          `#content__attachments-${this.parent.id} .new-marvinjs-upload-button`,
          () => this.$emit('attachment:uploaded')
        );
      },
      openWopiFileModal() {
        this.initWopiFileModal(this.parent, (_e, data, status) => {
          if (status === 'success') {
            this.$emit('attachment:uploaded', data);
          } else {
            HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
          }
        });
      },
      handleDropdownPosition() {
        this.$refs.actionsDropdownButton.classList.toggle("dropup", !this.isInViewport(this.$refs.actionsDropdown));
      },
      isInViewport(el) {
          let rect = el.getBoundingClientRect();

          return (
              rect.top >= 0 &&
              rect.left >= 0 &&
              rect.bottom <= (window.innerHeight || $(window).height()) &&
              rect.right <= (window.innerWidth || $(window).width())
          );
      },
    }
  }
</script>
