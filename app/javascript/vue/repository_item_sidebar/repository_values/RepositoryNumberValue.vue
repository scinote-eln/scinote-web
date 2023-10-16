<template>
  <div id="repository-number-value-wrapper" class="flex flex-col min-min-h-[46px] h-auto gap-[6px]">
    <div class="font-inter text-sm font-semibold leading-5 flex justify-between">
      <div>{{ colName }}</div>
      <div @click="toggleExpandContent" class="font-inter text-sm font-normal leading-5 text-sn-blue cursor-pointer">
        {{ this.contentExpanded ? i18n.t('repositories.item_card.repository_number_value.collapse') :
          i18n.t('repositories.item_card.repository_number_value.expand') }}
      </div>
    </div>
    <div v-if="colVal" ref="numberRef"
      class="text-sn-dark-grey font-inter text-sm font-normal leading-5 min-h-[20px] overflow-scroll"
      :class="{ 'max-h-[60px]': !contentExpanded, 'max-h-[600px]': contentExpanded }">
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
  data() {
    return {
      contentExpanded: false
    }
  },
  methods: {
    toggleExpandContent() {
      this.contentExpanded = !this.contentExpanded
    },
  },
}
</script>
