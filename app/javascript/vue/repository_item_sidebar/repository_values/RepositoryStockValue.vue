<template>
  <div id="repository-stock-value-wrapper" class="flex flex-col min-min-h-[46px] h-auto gap-[6px]">
    <div class="font-inter text-sm font-semibold leading-5 relative">
      <span class="truncate w-full inline-block pr-[50px]">{{ colName }}</span>
      <a style="text-decoration: none;" class="absolute right-0 btn-text-link font-normal export-consumption-button"
        v-if="permissions?.can_export_repository_stock === true && colVal?.stock_formatted" :data-rows="JSON.stringify([repositoryRowId])"
        :data-object-id="repositoryId">
        {{ i18n.t('repositories.item_card.stock_export') }}
      </a>
    </div>
    <a style="text-decoration: none;"
      :class="`border-solid border-[1px] manage-repository-stock-value-link text-sn-dark-grey font-inter text-sm font-normal leading-5 w-full rounded relative sci-cursor-edit block ${borderColor}`"
      @click="enableEditing"
      :data-manage-stock-url="stockValueUrl"
      :data-repository-row-id="repositoryId"
    >
      <div v-if="values?.stock_formatted" class="text-sn-dark-grey font-inter text-sm font-normal leading-5 p-2 stock-value">
        {{ values.stock_formatted }}
      </div>
      <div v-else class="text-sn-dark-grey font-inter text-sm font-normal leading-5 p-2">
        {{ i18n.t('repositories.item_card.repository_stock_value.no_stock') }}
      </div>
      <span class="absolute right-2 top-1.5" v-if="values?.reminder === true">
        <Reminder :value="colVal" />
      </span>
    </a>
  </div>
</template>

<script>
  import Reminder from '../reminder.vue';
  export default {
    name: 'RepositoryStockValue',
    components: {
      Reminder
    },
    computed: {
      borderColor() {
        return this.isEditing ? 'border-sn-science-blue' : 'border-sn-light-grey hover:border-sn-sleepy-grey';
      }
    },
    data() {
      return {
        stock_formatted: null,
        stock_amount: null,
        low_stock_threshold: null,
        isEditing: null,
        values: null,
        stockValueUrl: null
      }
    },
    props: {
      data_type: String,
      colId: Number,
      colName: String,
      colVal: Object,
      repositoryId: Number,
      repositoryRowId: null,
      permissions: null,
      actions: null, 
    },
    mounted() {
      this.values = this.colVal;
      this.stockValueUrl = this.actions.stock.stock_value_url
    },
    methods: {
      enableEditing(){
        this.isEditing = true
        const $this = this;
        // disable edit
        $('#manageStockValueModal').on('hide.bs.modal', function() {
          $this.isEditing = false;
        })
      }
    }
  }
</script>
