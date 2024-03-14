<template>
  <div
    ref="modal"
    class="modal fade"
    tabindex="-1"
    role="dialog"
    aria-labelledby="manage-stock-value"
  >
    <div class="modal-dialog" role="document" v-if="stockValue">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close self-start" data-dismiss="modal" :aria-label="i18n.t('general.close')">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title">
            <template v-if="stockValue?.id">
              {{ i18n.t('repository_stock_values.manage_modal.edit_title', { item: repositoryRowName }) }}
            </template>
            <template v-else>
              {{ i18n.t('repository_stock_values.manage_modal.title', { item: repositoryRowName }) }}
            </template>
          </h4>
        </div>
        <div class="modal-body !pt-[6px]">
          <p class="text-sm pb-6"> {{ i18n.t('repository_stock_values.manage_modal.enter_amount') }}</p>
          <form class="flex flex-col gap-6" @submit.prevent novalidate>
            <fieldset class="w-full flex justify-between">
              <div class="flex flex-col w-40">
                <label class="sci-label" for="operations">{{ i18n.t('repository_stock_values.manage_modal.operation') }}</label>
                <Select
                  :disabled="!stockValue?.id"
                  :value="operation"
                  :options="operations"
                  @change="setOperation"
                ></Select>
              </div>
              <div class="flex flex-col w-40">
                <Input
                  @update="value => amount = value"
                  name="stock_amount"
                  id="stock-amount"
                  type="number"
                  :value="amount"
                  :decimals="stockValue.decimals"
                  :placeholder="i18n.t('repository_stock_values.manage_modal.amount_placeholder_new')"
                  :label="i18n.t('repository_stock_values.manage_modal.amount')"
                  :required="true"
                  :min="0"
                  :error="errors.amount"
                />
              </div>
              <div class="flex flex-col w-40">
                <label class="sci-label" :class="{ 'error': !!errors.unit }" for="stock-unit">
                  {{ i18n.t('repository_stock_values.manage_modal.unit') }}
                </label>
                <Select
                  :disabled="['add', 'remove'].includes(operation)"
                  :value="unit"
                  :options="units"
                  :placeholder="i18n.t('repository_stock_values.manage_modal.unit_prompt')"
                  @change="unit = $event"
                  :className="`${errors.unit ? 'error' : ''}`"
                ></Select>
                <div class="text-sn-coral text-xs" :class="{ visible: errors.unit, invisible: !errors.unit }">
                  {{ errors.unit }}
                </div>
              </div>
            </fieldset>
            <template v-if="stockValue?.id">
              <div class="flex justify-between w-full items-center">
                <div class="flex flex-col w-[220px] h-24 border-rounded bg-sn-super-light-grey justify-between text-center">
                  <span class="text-sm text-sn-grey leading-5 pt-2">{{ i18n.t('repository_stock_values.manage_modal.current_stock') }}</span>
                  <span class="text-2xl text-sn-black font-semibold leading-8" :class="{ 'text-sn-delete-red': stockValue.amount < 0 }">{{ stockValue.amount }}</span>
                  <span class="text-sm text0sn-black leading-5 pb-2">{{ initUnitLabel }}</span>
                </div>
                <i class="sn-icon sn-icon-arrow-right"></i>
                <div class="flex flex-col w-[220px] h-24 border-rounded bg-sn-super-light-grey justify-between text-center">
                  <span class="text-sm text-sn-grey leading-5 pt-2">{{ i18n.t('repository_stock_values.manage_modal.new_stock') }}</span>
                  <span class="text-2xl text-sn-black font-semibold leading-8" :class="{ 'text-sn-delete-red': newAmount < 0 }">
                    {{ (newAmount || newAmount === 0) ? newAmount : '-' }}
                  </span>
                  <span class="text-sm text0sn-black leading-5 pb-2">{{ unitLabel }}</span>
                </div>
              </div>
            </template>
            <div class="repository-stock-reminder-selector flex">
              <div class="sci-checkbox-container my-auto">
                <input type="checkbox" name="reminder-enabled" tabindex="4" class="sci-checkbox" id="reminder-selector-checkbox" :checked="reminderEnabled" @change="reminderEnabled = $event.target.checked"/>
                <span class="sci-checkbox-label"></span>
              </div>
              <span class="ml-2">{{ i18n.t('repository_stock_values.manage_modal.create_reminder') }}</span>
            </div>
            <div v-if="reminderEnabled" class="stock-reminder-value flex gap-2 items-center w-40">
              <Input
                  @update="value => lowStockTreshold = value"
                  name="treshold_amount"
                  id="treshold-amount"
                  type="number"
                  :value="lowStockTreshold"
                  :decimals="stockValue.decimals"
                  :placeholder="i18n.t('repository_stock_values.manage_modal.amount_placeholder_new')"
                  :required="true"
                  :label="i18n.t('repository_stock_values.manage_modal.reminder_at')"
                  :min="0"
                  :error="errors.tresholdAmount"
                />
              <span class="text-sm font-normal mt-5">
                {{ unitLabel }}
              </span>
            </div>
            <div class="sci-input-container flex flex-col" :data-error-text="i18n.t('repository_stock_values.manage_modal.comment_limit')">
              <label class="text-sn-grey text-sm font-normal" for="stock-value-comment">{{ i18n.t('repository_stock_values.manage_modal.comment') }}</label>
              <input class="sci-input-field"
                @input="event => comment = event.target.value"
                type="text"
                name="comment"
                id="stock-value-comment"
                :placeholder="i18n.t('repository_stock_values.manage_modal.comment_placeholder')"
              />
            </div>
          </form>
        </div>
        <div class="modal-footer">
          <button type='button' class='btn btn-secondary' data-dismiss='modal'>
            {{ i18n.t('general.cancel') }}
          </button>
          <button class="btn btn-primary" @click="validateAndsaveStockValue" :disabled="isSaving">
            {{ i18n.t('repository_stock_values.manage_modal.save_stock') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import Decimal from 'decimal.js';
import Select from '../shared/legacy/select.vue';
import Input from '../shared/legacy/input.vue';

export default {
  name: 'ManageStockValueModal',
  components: {
    Select,
    Input
  },
  data() {
    return {
      operation: null,
      operations: [],
      stockValue: null,
      amount: null,
      repositoryRowName: null,
      stockUrl: null,
      units: null,
      unit: null,
      reminderEnabled: false,
      isSaving: false,
      lowStockTreshold: null,
      comment: null,
      errors: {}
    };
  },
  computed: {
    unitLabel() {
      const currentUnit = this.units?.find((option) => option[0] === this.unit);
      return currentUnit ? currentUnit[1] : '';
    },
    initUnitLabel() {
      const unit = this.units?.find((option) => option[0] === this.stockValue?.unit);
      return unit ? unit[1] : '';
    },
    newAmount() {
      const currentAmount = this.stockValue?.amount ? new Decimal(this.stockValue?.amount || 0) : null;
      const amount = new Decimal(this.amount || 0);
      let value;
      switch (this.operation) {
        case 'add':
          value = currentAmount.plus(amount);
          break;
        case 'remove':
          value = currentAmount.minus(amount);
          break;
        default:
          value = amount;
          break;
      }
      return Number(value);
    }
  },
  created() {
    window.manageStockModalComponent = this;
  },
  beforeDestroy() {
    delete window.manageStockModalComponent;
  },
  mounted() {
    // Focus stock amount input field
    $(this.$refs.modal).on('show.bs.modal', () => {
      setTimeout(() => {
        $('#stock-amount')[0]?.focus();
      }, 500);
    });
  },
  methods: {
    setOperation($event) {
      if ($event !== this.operation) {
        this.amount = null;
      }
      this.operation = $event;
      if (['add', 'remove'].includes($event)) {
        this.unit = this.stockValue.unit;
      }
    },
    fetchStockValueData(stockValueUrl) {
      if (!stockValueUrl) return;
      $.ajax({
        method: 'GET',
        url: stockValueUrl,
        dataType: 'json',
        success: (result) => {
          this.repositoryRowName = result.repository_row_name;
          this.stockValue = result.stock_value;
          this.amount = this.stockValue?.amount && Number(new Decimal(this.stockValue.amount));
          this.units = result.stock_value.units;
          this.unit = result.stock_value.unit;
          this.reminderEnabled = result.stock_value.reminder_enabled;
          this.lowStockTreshold = result.stock_value.low_stock_treshold;
          this.operation = 'set';
          this.stockUrl = result.stock_url;
          /* eslint-disable no-undef */
          this.operations = [
            ['set', `${I18n.t('repository_stock_values.manage_modal.set')}`],
            ['add', `${I18n.t('repository_stock_values.manage_modal.add')}`],
            ['remove', `${I18n.t('repository_stock_values.manage_modal.remove')}`]
          ];
          /* eslint-enable no-undef */
          this.errors = {};
        }
      });
    },
    closeModal() {
      $(this.$refs.modal).modal('hide');
    },
    showModal(stockValueUrl, closeCallback) {
      $(this.$refs.modal).modal('show');
      this.fetchStockValueData(stockValueUrl);
      this.closeCallback = closeCallback;
    },
    validateAndsaveStockValue() {
      const newErrors = {};
      this.errors = newErrors;
      if (!this.unit) { newErrors.unit = I18n.t('repository_stock_values.manage_modal.unit_error'); }
      if (!this.amount) { newErrors.amount = I18n.t('repository_stock_values.manage_modal.amount_error'); }
      if (this.amount && this.amount < 0) { newErrors.amount = I18n.t('repository_stock_values.manage_modal.negative_error'); }
      if (this.reminderEnabled && !this.lowStockTreshold) { newErrors.tresholdAmount = I18n.t('repository_stock_values.manage_modal.amount_error'); }

      this.errors = newErrors;

      if (!$.isEmptyObject(newErrors)) return;
      this.isSaving = true;

      const $this = this;
      $.ajax({
        method: 'POST',
        url: this.stockUrl,
        dataType: 'json',
        data: {
          repository_stock_value: {
            unit_item_id: this.unit,
            amount: this.newAmount,
            comment: this.comment,
            low_stock_threshold: this.reminderEnabled ? this.lowStockTreshold : null
          },
          operator: this.operations.find((operation) => operation[0] == this.operation)?.[0],
          change_amount: Math.abs(this.amount)

        },
        success: (result) => {
          $this.stockValue = null;
          $this.isSaving = false;
          $this.closeModal();
          $this.closeCallback && $this.closeCallback(result);
        }
      });
    }
  }
};
</script>
