<template>
  <div id="repository-asset-value-wrapper" class="flex flex-col min-min-h-[46px] h-auto gap-[6px]">
    <div class="font-inter text-sm font-semibold leading-5 truncate">
      {{ colName }}
    </div>
    <div v-if="file_name" @mouseover="tooltipShowing = true" @mouseout="tooltipShowing = false"
      class="w-full cursor-pointer  relative">
      <a class="w-full inline-block file-preview-link truncate hover:no-underline hover:text-sn-science-blue text-sn-science-blue"
        :id="modalPreviewLinkId" data-no-turbolink="true" data-id="true" data-status="asset-present"
        :data-preview-url=this?.preview_url :href=this?.url>
        {{ file_name }}
      </a>
      <tooltip-preview v-if="tooltipShowing && medium_preview_url" :id="id" :url="url" :file_name="file_name"
        :preview_url="preview_url" :icon_html="icon_html" :medium_preview_url="medium_preview_url">
      </tooltip-preview>
    </div>
    <div v-else class="text-sn-dark-grey font-inter text-sm font-normal leading-5">
      {{ i18n.t('repositories.item_card.repository_asset_value.no_asset') }}
    </div>
  </div>
</template>

<script>
import TooltipPreview from './TooltipPreview.vue'

export default {
  name: 'RepositoryAssetvalue',
  components: {
    "tooltip-preview": TooltipPreview
  },
  data() {
    return {
      tooltipShowing: false,
      id: null,
      url: null,
      preview_url: null,
      file_name: null,
      icon_html: null,
      medium_preview_url: null,
    }
  },
  props: {
    data_type: String,
    colId: Number,
    colName: String,
    colVal: Object
  },
  created() {
    if (!this.colVal) return

    this.id = this.colVal.id
    this.url = this.colVal.url
    this.preview_url = this.colVal.preview_url
    this.file_name = this.colVal.file_name
    this.icon_html = this.colVal.icon_html
    this.medium_preview_url = this.colVal.medium_preview_url
  },
  computed: {
    modalPreviewLinkId() {
      return `modal_link${this.id}`
    }
  },
}
</script>
