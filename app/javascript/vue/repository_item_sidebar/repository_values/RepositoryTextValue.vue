<template>
  <div id="repository-text-value-wrapper" class="flex flex-col min-min-h-[46px] h-auto gap-[6px]">
    <div class="font-inter text-sm font-semibold leading-5 flex justify-between">
      <div>{{ colName }}</div>
      <div @click="toggleExpandContent" v-show="expendable" class="font-normal leading-5 btn-text-link">
        {{ this.contentExpanded ? i18n.t('repositories.item_card.repository_text_value.collapse') :
          i18n.t('repositories.item_card.repository_text_value.expand') }}
      </div>
    </div>
    <div v-if="edit" ref="textRef" class="text-sn-dark-grey font-inter text-sm font-normal leading-5 overflow-y-auto"
         :class="{ 'max-h-[60px]': !contentExpanded,
                   'max-h-[600px]': contentExpanded }">
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
      contentExpanded: false,
      expendable: false
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
  },
  mounted() {
    this.$nextTick(() => {
      const textHeight = this.$refs.textRef.scrollHeight
      this.expendable = textHeight > 60 // 60px
    })
  },
}
</script>
