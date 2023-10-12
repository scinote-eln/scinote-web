<template>
  <div id="repository-number-value-wrapper" class="flex flex-col min-min-h-[46px] h-auto gap-[6px]">
    <div class="font-inter text-sm font-semibold leading-5">
      {{ colName }}
    </div>
    <div v-if="colVal" class="text-sn-dark-grey font-inter text-sm font-normal leading-5">
      {{ colVal }}
    </div>
    <div v-else class="text-sn-dark-grey font-inter text-sm font-normal leading-5">
      {{ i18n.t('repositories.item_card.repository_number_value.no_number') }}
    </div>
  </div>
</template>

<script>
export default {
  name: 'RepositoryNumberValue',
  props: {
    data_type: String,
    colId: Number,
    colName: String,
    colVal: Number
  },
}
</script>
