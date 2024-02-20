<template>
  <div id="repository-stock-value-wrapper" class="flex flex-col min-min-h-[46px] h-auto gap-2">
    <div class="font-inter text-sm font-semibold leading-5 relative h-[20px] flex flex-row">
      <div class="flex flex-row gap-1">
        <span class="truncate w-fit inline-block max-w-[18rem]" :title="colName">{{ colName }}</span>
        <div v-if="values?.reminder" >
          <div v-if="isBetweenThresholdAndDepleted"
            class="bg-sn-alert-brittlebush w-1.5 h-1.5 min-w-[0.375rem] min-h-[0.375rem] rounded hover:cursor-pointer"
            :title="values.reminder_text">
          </div>
          <div v-else
            class="bg-sn-alert-passion w-1.5 h-1.5 min-w-[0.375rem] min-h-[0.375rem] rounded hover:cursor-pointer"
            :title="values.reminder_text">
          </div>
        </div>
      </div>
      <a style="text-decoration: none;" class="absolute right-0 btn-text-link font-normal export-consumption-button"
        v-if="permissions?.can_export_repository_stock === true && values?.stock_formatted" :data-rows="JSON.stringify([repositoryRowId])"
        :data-object-id="repositoryId">
        {{ i18n.t('repositories.item_card.stock_export') }}
      </a>
    </div>
    <a style="text-decoration: none;"
      class="text-sn-dark-grey font-inter text-sm font-normal leading-5 w-full rounded relative block"
      :class="editableClassName"
      @click="enableEditing"
      :data-manage-stock-url="values?.stock_url"
      :data-repository-row-id="repositoryId"
      :data-e2e="'e2e-BT-repoItemSBcustomColumns-input' + colId"
    >
      <div v-if="values?.stock_formatted" :data-manage-stock-url="values?.stock_url"
        class="text-sn-dark-grey font-inter text-sm font-normal leading-5 stock-value overflow-hidden text-ellipsis whitespace-nowrap">
        {{ values.stock_formatted }}
      </div>
      <div v-else class="font-inter text-sm font-normal leading-5" :class="{ 'text-sn-dark-grey': !canEdit, 'text-sn-grey': canEdit }">
        {{ i18n.t(`repositories.item_card.repository_stock_value.${canEdit ? 'placeholder' : 'no_stock'}`) }}
      </div>
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
    editableClassName() {
      const className = 'border-solid border-[1px] p-2 pl-3 manage-repository-stock-value-link sci-cursor-edit';
      if (this.canEdit && this.isEditing) return `${className} border-sn-science-blue`;
      if (this.canEdit) return `${className} border-sn-light-grey hover:border-sn-sleepy-grey`;
      return '';
    },
    isBetweenThresholdAndDepleted() {
      return Number(this.values.stock_amount) <= Number(this.values.low_stock_threshold)
      && (Number(this.values.stock_amount) > 0);
    }
  },
  data() {
    return {
      stock_formatted: null,
      stock_amount: null,
      low_stock_threshold: null,
      isEditing: false,
      values: null
    };
  },
  props: {
    data_type: String,
    colId: Number,
    colName: String,
    colVal: Object,
    repositoryId: Number,
    repositoryRowId: null,
    permissions: null,
    canEdit: { type: Boolean, default: false },
    actions: null
  },
  mounted() {
    this.values = this.colVal || {};
    this.values.stock_url = this.actions?.stock_value_url;
    window.manageStockCallback = this.submitCallback;
  },
  unmounted() {
    delete window.manageStockCallback;
  },
  methods: {
    enableEditing() {
      this.isEditing = true;
      const $this = this;
      // disable edit
      $('#manageStockValueModal').on('hide.bs.modal', () => {
        $this.isEditing = false;
      });
    },
    submitCallback(values) {
      if (values) this.values = values;
    }
  }
};
</script>
