<template>
  <div id="repository-text-value-wrapper" class="flex flex-col min-min-h-[46px] h-auto gap-[6px]">
    <div class="font-inter text-sm font-semibold leading-5">
      {{ colName }}
    </div>
    <div v-if="edit" class="text-sn-dark-grey font-inter text-sm font-normal leading-5">
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
    }
  },
  props: {
    data_type: String,
    colId: Number,
    colName: String,
    colVal: Object
  },
  created() {
    this.edit = this?.colVal?.edit
    this.view = this?.colVal?.view
  }
}
</script>
