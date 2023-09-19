<template>
  <div id="repository-asset-value-wrapper" class="flex flex-col min-min-h-[46px] h-auto gap-[6px]">
    <div class="font-inter text-sm font-semibold leading-5">
      {{ colName }}
    </div>
    <div v-if="file_name" @mouseover="tooltipShowing = true" @mouseout="tooltipShowing = false"
      class="w-fit cursor-pointer text-sn-science-blue">
      {{ file_name }}
      <tooltip-preview v-if="tooltipShowing" :url="url" :file_name="file_name" :preview_url="preview_url"
        :icon_html="icon_html"></tooltip-preview>
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
      icon_html: null
    }
  },
  props: {
    data_type: String,
    colId: Number,
    colName: String,
    colVal: Object
  },
  created() {
    this.id = this.colVal.id
    this.url = this.colVal.url
    this.preview_url = this.colVal.preview_url
    this.file_name = this.colVal.file_name
    this.icon_html = this.colVal.icon_html
  }
}
</script>
