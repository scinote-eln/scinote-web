<template>
  <div id="repository-text-value-wrapper" class="flex flex-col min-min-h-[46px] h-auto gap-[6px]">
    <div class="font-inter text-sm font-semibold leading-5 flex justify-between">
      <div>{{ colName }}</div>
      <div @click="toggleExpandContent" class="font-inter text-sm font-normal leading-5 text-sn-blue cursor-pointer">
        {{ this.contentExpanded ? i18n.t('repositories.item_card.repository_text_value.collapse') :
          i18n.t('repositories.item_card.repository_text_value.expand') }}
      </div>
    </div>
    <div v-if="edit" class="text-sn-dark-grey font-inter text-sm font-normal leading-5 min-h-[20px] overflow-scroll"
      :class="{ 'max-h-[60px]': !contentExpanded, 'max-h-[600px]': contentExpanded }" ref="textRef">
      {{ edit }}
    </div>
    <div v-else class="text-sn-dark-grey font-inter text-sm font-normal leading-5">
      {{ i18n.t('repositories.item_card.repository_text_value.no_text') }}
    </div>
  </div>
</template>

<script>
export default {
  name: 'RepositoryTextValue',
  data() {
    return {
      edit: null,
      view: null,
      contentExpanded: false
    }
  },
  props: {
    data_type: String,
    colId: Number,
    colName: String,
    colVal: Object
  },
  methods: {
    toggleExpandContent() {
      this.contentExpanded = !this.contentExpanded
    },
  },
  created() {
    if (!this.colVal) return

    this.edit = this.colVal.edit
    this.view = this.colVal.view
  }
}
</script>
