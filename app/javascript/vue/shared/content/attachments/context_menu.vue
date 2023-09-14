<template>
  <div class="dropdown asset-context-menu" ref="menu">
    <button class="btn btn-light btn-xs dropdown-toggle icon-btn" type="button" id="dropdownAssetContextMenu" data-toggle="dropdown" aria-haspopup="true" aria-expanded="true">
      <i class="sn-icon sn-icon-more-hori"></i>
    </button>

    <ul class="dropdown-menu dropdown-menu-right"
        aria-labelledby="dropdownAssetContextMenu"
        :data-asset-id="attachment.id"
    >
      <li v-if="attachment.attributes.wopi && attachment.attributes.urls.edit_asset" >
        <a :href="attachment.attributes.urls.edit_asset"
           id="wopi_file_edit_button"
           class="btn btn-light"
           :class="attachment.attributes.wopi_context.edit_supported ? '' : 'disabled'"
           :title="attachment.attributes.wopi_context.title"
           target="_blank"
        >
          {{ attachment.attributes.wopi_context.button_text }}
        </a>
      </li>
      <li v-if="attachment.attributes.asset_type == 'gene_sequence' && attachment.attributes.urls.open_vector_editor_edit">
        <a class="ove-edit-button" @click="openOVEditor(attachment.attributes.urls.open_vector_editor_edit)">
          {{ i18n.t('open_vector_editor.edit_sequence') }}
        </a>
      </li>
      <li v-if="attachment.attributes.asset_type == 'marvinjs' && attachment.attributes.urls.marvin_js_start_edit">
        <a class="marvinjs-edit-button"
           :data-sketch-id="attachment.id"
           :data-update-url="attachment.attributes.urls.marvin_js"
           :data-sketch-start-edit-url="attachment.attributes.urls.marvin_js_start_edit"
           :data-sketch-name="attachment.attributes.metadata.name"
           :data-sketch-description="attachment.attributes.metadata.description"
        >
          {{ i18n.t('assets.file_preview.edit_in_marvinjs') }}
        </a>
      </li>
      <li v-if="attachment.attributes.asset_type != 'marvinjs'
               && attachment.attributes.image_editable
               && attachment.attributes.urls.start_edit_image">
        <a class="image-edit-button"
           :data-image-id="attachment.id"
           :data-image-name="attachment.attributes.file_name"
           :data-image-url="attachment.attributes.urls.asset_file"
           :data-image-quality="attachment.attributes.image_context.quality"
           :data-image-mime-type="attachment.attributes.image_context.type"
           :data-image-start-edit-url="attachment.attributes.urls.start_edit_image"
        >
          {{ i18n.t('assets.file_preview.edit_in_scinote') }}
        </a>
      </li>
      <li>
        <a :href="attachment.attributes.urls.download" data-turbolinks="false">
          {{ i18n.t('Download') }}
        </a>
      </li>
      <template v-if="attachment.attributes.urls.move_targets">
        <li>
          <a @click.prevent.stop="showMoveModal">
            {{ i18n.t("assets.context_menu.move") }}
          </a>
        </li>
      </template>
      <template v-if="attachment.attributes.urls.delete">
        <li>
          <a @click.prevent.stop="deleteModal = true">
            {{ i18n.t("assets.context_menu.delete") }}
          </a>
        </li>
      </template>
      <template v-if="attachment.attributes.urls.toggle_view_mode">
        <li role="separator" class="divider"></li>
        <li class="divider-label">
          {{ i18n.t("assets.context_menu.set_view_size") }}
        </li>
        <li v-for="(viewMode, index) in viewModeOptions" :key="`viewMode_${index}`">
          <a
            class="change-preview-type"
            :class="viewMode == attachment.attributes.view_mode ? 'selected' : ''"
            @click.prevent.stop="changeViewMode(viewMode)"
            v-html="i18n.t(`assets.context_menu.${viewMode}_html`)"
          ></a>
        </li>
      </template>
    </ul>
    <deleteAttachmentModal
        v-if="deleteModal"
        :fileName="attachment.attributes.file_name"
        @confirm="deleteAttachment"
        @cancel="deleteModal = false"
    />
    <moveAssetModal v-if="movingAttachment"
                      :parent_type="attachment.attributes.parent_type"
                      :targets_url="attachment.attributes.urls.move_targets"
                      @confirm="moveAttachment($event)" @cancel="closeMoveModal"/>
  </div>
</template>

<script>
  import deleteAttachmentModal from './delete_modal.vue'
  import moveAssetModal from '../modal/move.vue'
  import MoveMixin from './mixins/move.js'

  export default {
    name: 'contextMenu',
    components: { deleteAttachmentModal, moveAssetModal },
    mixins: [MoveMixin],
    props: {
      attachment: {
        type: Object,
        required: true
      }
    },
    data() {
      return {
        viewModeOptions: ['inline', 'thumbnail', 'list'],
        deleteModal: false
      }
    },
    mounted() {
      $(this.$refs.menu).on('show.bs.dropdown', function() {
        let screenHeight = screen.height;
        let dropdownPosition = this.getBoundingClientRect().y;
        let dropdownMenu = $(this).find('.dropdown-menu');
        if ((screenHeight / 2) < dropdownPosition) {
          dropdownMenu.css({ top: 'unset', bottom: '100%' });
        } else {
          dropdownMenu.css({ bottom: 'unset', top: '100%' });
        }
      })
    },
    methods: {
      changeViewMode(viewMode) {
        this.$emit('attachment:viewMode', viewMode)
        $.ajax({
          url: this.attachment.attributes.urls.toggle_view_mode,
          type: 'PATCH',
          dataType: 'json',
          data: { asset: { view_mode: viewMode } }
        });
      },
      deleteAttachment() {
        this.deleteModal = false
        this.$emit('attachment:delete')
      },
      openOVEditor(url) {
        window.showIFrameModal(url);
      }
    }
  }
</script>
