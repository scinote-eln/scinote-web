<template>
  <div class="step-attachments">
    <div class="attachments-actions">
      <div class="title">
        <h3>{{ i18n.t('protocols.steps.files', {count: attachments.length}) }}</h3>
      </div>
      <div class="actions" v-if="step.attributes.attachments_manageble && attachmentsReady">
        <div ref="actionsDropdownButton" class="dropdown sci-dropdown">
          <button class="btn btn-light dropdown-toggle" type="button" id="dropdownAttachmentsOptions" data-toggle="dropdown" aria-haspopup="true" aria-expanded="true">
            <span>{{ i18n.t("protocols.steps.attachments.manage") }}</span>
            <span class="sn-icon sn-icon-down"></span>
          </button>
          <ul ref="actionsDropdown" class="dropdown-menu dropdown-menu-right dropdown-attachment-options"
              aria-labelledby="dropdownAttachmentsOptions"
              :data-step-id="step.id"
          >
            <li class="divider-label">{{ i18n.t("protocols.steps.attachments.add") }}</li>
            <li>
              <a class="action-link attachments-view-mode" @click="$emit('attachments:openFileModal')">
                <i class="sn-icon sn-icon-import"></i>
                {{ i18n.t('protocols.steps.attachments.menu.file_from_pc') }}
              </a>
            </li>
            <li v-if="step.attributes.wopi_enabled">
              <a @click="openWopiFileModal" class="create-wopi-file-btn" tabindex="0" @keyup.enter="openWopiFileModal">
                <img :src="step.attributes.wopi_context.icon"/>
                {{ i18n.t('protocols.steps.attachments.menu.office_file') }}
              </a>
            </li>
            <li v-if="step.attributes.marvinjs_enabled">
              <a
                class="new-marvinjs-upload-button"
                :data-object-id="step.id"
                data-object-type="Step"
                :data-marvin-url="step.attributes.marvinjs_context.marvin_js_asset_url"
                :data-sketch-container="`.attachments[data-step-id=${step.id}]`"
              >
                <span class="new-marvinjs-upload-icon">
                  <img :src="step.attributes.marvinjs_context.icon">
                </span>
                  {{ i18n.t('protocols.steps.attachments.menu.chemical_drawing') }}
              </a>
            </li>
            <li role="separator" class="divider"></li>
            <li class="divider-label">{{ i18n.t("protocols.steps.attachments.sort_by") }}</li>
            <li v-for="(orderOption, index) in orderOptions" :key="`orderOption_${index}`">
              <a class="action-link change-order"
                @click="changeAttachmentsOrder(orderOption)"
                :class="step.attributes.assets_order == orderOption ? 'selected' : ''"
              >
                {{ i18n.t(`general.sort_new.${orderOption}`) }}
              </a>
            </li>
            <template v-if="step.attributes.urls.update_asset_view_mode_url">
              <li role="separator" class="divider"></li>
              <li class="divider-label">{{ i18n.t("protocols.steps.attachments.attachments_view_mode") }}</li>
              <li v-for="(viewMode, index) in viewModeOptions" :key="`viewMode_${index}`">
                <a
                  class="attachments-view-mode action-link"
                  :class="viewMode == step.attributes.assets_view_mode ? 'selected' : ''"
                  @click="changeAttachmentsViewMode(viewMode)"
                  v-html="i18n.t(`protocols.steps.attachments.view_mode.${viewMode}_html`)"
                ></a>
              </li>
            </template>
          </ul>
        </div>
      </div>
    </div>
    <div class="attachments">
      <template v-for="(attachment, index) in attachmentsOrdered">
        <component
          :is="attachment_view_mode(attachmentsOrdered[index])"
          :key="attachment.id"
          :attachment="attachment"
          :stepId="parseInt(step.id)"
          @attachment:viewMode="updateAttachmentViewMode"
          @attachment:delete="deleteAttachment(attachment.id)"
        />
      </template>
    </div>
  </div>
</template>
<script>
  import listAttachment from './step_attachments/list.vue'
  import inlineAttachment from './step_attachments/inline.vue'
  import thumbnailAttachment from './step_attachments/thumbnail.vue'
  import uploadingAttachment from './step_attachments/uploading.vue'
  import emptyAttachment from './step_attachments/empty.vue'

  import WopiFileModal from './step_attachments/mixins/wopi_file_modal.js'

  export default {
    name: 'Attachments',
    props: {
      attachments: {
        type: Array,
        required: true
      },
      step: {
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
            switch(this.step.attributes.assets_order) {
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
      this.initOVE();
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
      initOVE() {
        $(window.iFrameModal).on('sequenceSaved', () => this.$emit('attachment:uploaded'));
      },
      initMarvinJS() {
        // legacy logic from app/assets/javascripts/sitewide/marvinjs_editor.js
        MarvinJsEditor.initNewButton(
          `#stepContainer${this.step.id} .new-marvinjs-upload-button`,
          () => this.$emit('attachment:uploaded')
        );
      },
      openWopiFileModal() {
        this.initWopiFileModal(this.step, (_e, data, status) => {
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
