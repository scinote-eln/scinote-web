<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content" data-e2e="e2e-MD-manageStock">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title" data-e2e="e2e-TX-manageStockModal-title">
            <template v-if="stockObject && stockObject.id">
              {{ i18n.t('repository_stock_values.manage_modal.edit_title', { item: repositoryRowName }) }}
            </template>
            <template v-else>
              {{ i18n.t('repository_stock_values.manage_modal.title', { item: repositoryRowName }) }}
            </template>
          </h4>
        </div>
        <div v-if="stockObject" class="modal-body !pt-[6px]">
          <p class="text-sm pb-6"> {{ i18n.t('repository_stock_values.manage_modal.enter_amount') }}</p>
          <div class="flex flex-col gap-6">
            <fieldset class="w-full flex justify-between">
              <div class="flex flex-col w-40">
                <label class="sci-label" for="operations">{{ i18n.t('repository_stock_values.manage_modal.operation') }}</label>
                <SelectDropdown
                  :disabled="!stockObject.id"
                  @change="setOperation"
                  :options="operations"
                  :value="operation"
                />
              </div>
              <div class="flex flex-col w-40">
                <label class="sci-label" for="operations">{{ i18n.t('repository_stock_values.manage_modal.amount') }}</label>
                <div class="sci-input-container-v2"  :class="{'error': errors.amount}" :data-error="errors.amount">
                  <input
                    type="text"
                    class="sci-input-field"
                    v-model="stockObject.amount"
                    :placeholder="i18n.t('repository_stock_values.manage_modal.amount_placeholder_new')"
                  >
                </div>
              </div>
              <div class="flex flex-col w-40">
                <label class="sci-label" :class="{ 'error': !!errors.unit }" for="stock-unit">
                  {{ i18n.t('repository_stock_values.manage_modal.unit') }}
                </label>
                <SelectDropdown
                  :disabled="['add', 'remove'].includes(operation)"
                  @change="stockObject.unit = $event; validateStockObject()"
                  :options="stockObject.units"
                  :placeholder="i18n.t('repository_stock_values.manage_modal.unit_prompt')"
                  :value="stockObject.unit"
                />
                <div class="text-sn-coral text-xs" :class="{ visible: errors.unit, invisible: !errors.unit }">
                  {{ errors.unit }}
                </div>
              </div>
            </fieldset>
            <template v-if="stockObject?.id">
              <div class="flex justify-between w-full items-center">
                <div class="flex flex-col w-[220px] h-24 border-rounded bg-sn-super-light-grey justify-between text-center">
                  <span class="text-sm text-sn-grey leading-5 pt-2">{{ i18n.t('repository_stock_values.manage_modal.current_stock') }}</span>
                  <span
                    class="text-2xl text-sn-black font-semibold leading-8"
                    :class="{ 'text-sn-delete-red': initialStockObject.amount < 0 }"
                    data-e2e="e2e-LB-manageStockModal-currentStock"
                  >
                    {{ initialStockObject.amount }}
                  </span>
                  <span class="text-sm text-sn-black leading-5 pb-2">{{ initUnitLabel }}</span>
                </div>
                <i class="sn-icon sn-icon-arrow-right"></i>
                <div class="flex flex-col w-[220px] h-24 border-rounded bg-sn-super-light-grey justify-between text-center">
                  <span class="text-sm text-sn-grey leading-5 pt-2">{{ i18n.t('repository_stock_values.manage_modal.new_stock') }}</span>
                  <span
                    class="text-2xl text-sn-black font-semibold leading-8"
                    :class="{ 'text-sn-delete-red': newAmount < 0 }"
                    data-e2e="e2e-LB-manageStockModal-newStock"
                  >
                    {{ (newAmount || newAmount === 0) ? newAmount : '-' }}
                  </span>
                  <span class="text-sm text-sn-black leading-5 pb-2">{{ unitLabel }}</span>
                </div>
              </div>
            </template>
            <div class="repository-stock-reminder-selector flex">
              <div class="sci-checkbox-container my-auto">
                <input
                  type="checkbox"
                  name="reminder-enabled"
                  tabindex="4"
                  class="sci-checkbox"
                  id="reminder-selector-checkbox"
                  :checked="stockObject.reminder_enabled"
                  @change="stockObject.reminder_enabled = $event.target.checked"
                  :dataE2e="'e2e-CB-invItems-manageStockModal-lowStock'"
                />
                <span class="sci-checkbox-label"></span>
              </div>
              <span class="ml-2">{{ i18n.t('repository_stock_values.manage_modal.create_reminder') }}</span>
            </div>
            <div v-if="stockObject.reminder_enabled" class="flex flex-col w-full">
              <label class="sci-label" :class="{ 'error': !!errors.tresholdAmount }" for="stock-comment">
                {{ i18n.t('repository_stock_values.manage_modal.reminder_at') }}
              </label>
              <div  class="stock-reminder-value flex gap-2 items-center">
                <div class="sci-input-container-v2 w-40">
                  <input
                    type="text"
                    class="sci-input-field"
                    v-model="stockObject.low_stock_treshold"
                    :placeholder="i18n.t('repository_stock_values.manage_modal.amount_placeholder_new')"
                  >
                </div>
                <span class="text-sm font-normal mt-5 shrink-0">
                  {{ unitLabel }}
                </span>
              </div>
            </div>
            <div class="flex flex-col w-full">
              <label class="sci-label" :class="{ 'error': !!errors.comment }" for="stock-comment">
                {{ i18n.t('repository_stock_values.manage_modal.comment') }}
              </label>
              <div class="sci-input-container-v2" :class="{'error': errors.comment}" :data-error="errors.comment">
                <input
                  type="text"
                  v-model="this.stockObject.comment"
                  :placeholder="i18n.t('repository_stock_values.manage_modal.comment_placeholder')"
                >
              </div>
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button type='button' class='btn btn-secondary' data-dismiss='modal' data-e2e='e2e-BT-invItems-manageStockModal-cancel'>
            {{ i18n.t('general.cancel') }}
          </button>
          <button class="btn btn-primary" @click="saveStockValue" :disabled="isSaving || !isValid" data-e2e='e2e-BT-invItems-manageStockModal-save'>
            {{ i18n.t('repository_stock_values.manage_modal.save_stock') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import Decimal from 'decimal.js';
import SelectDropdown from '../../shared/select_dropdown.vue';
import modalMixin from '../../shared/modal_mixin';
import axios from '../../../packs/custom_axios.js';

export default {
  name: 'StockValueModal',
  components: {
    SelectDropdown
  },
  mixins: [modalMixin],
  props: {
    stockUrl: {
      type: String,
      required: true
    },
  },
  data() {
    return {
      initialStockObject: null,
      stockObject: null,
      operation: 'set',
      repositoryRowName: null,
      updateStockUrl: null,
      isSaving: false,
      errors: {}
    };
  },
  watch: {
    'stockObject.amount'(newValue) {
      this.stockObject.amount = this.validateDecimals(newValue);
    },
    'stockObject.low_stock_treshold'(newValue) {
      this.stockObject.low_stock_treshold = this.validateDecimals(newValue);
    }
  },
  computed: {
    isValid() {
      return Object.keys(this.errors).length === 0;
    },
    operations() {
      return [
        ['set', I18n.t('repository_stock_values.manage_modal.set')],
        ['add', I18n.t('repository_stock_values.manage_modal.add')],
        ['remove', I18n.t('repository_stock_values.manage_modal.remove')]
      ]
    },
    unitLabel() {
      const currentUnit = this.stockObject.units?.find((option) => option[0] === this.stockObject.unit);
      return currentUnit ? currentUnit[1] : '';
    },
    initUnitLabel() {
      const unit = this.stockObject.units?.find((option) => option[0] === this.initialStockObject.unit);
      return unit ? unit[1] : '';
    },
    newAmount() {
      const currentAmount = this.initialStockObject?.amount ? new Decimal(this.initialStockObject?.amount || 0) : null;
      const amount = new Decimal(this.stockObject?.amount || 0);
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
    this.fetchStockObject();
  },
  methods: {
    validateDecimals(rawValue) {
      if (rawValue === null || rawValue === '' || rawValue === undefined) return rawValue;

      const decimals = this.stockObject?.decimals || 0;
      const regexp = decimals === 0 ? /[^-0-9]/g : /[^-0-9.]/g;
      const decimalsRegex = new RegExp(`^-?\\d*(\\.\\d{0,${decimals}})?`);

      let formattedValue = rawValue;
      formattedValue = formattedValue.replace(regexp, '');
      formattedValue = formattedValue.match(decimalsRegex)[0];
      return formattedValue
    },

    setOperation(newOperation) {
      if (newOperation !== this.operation) {
        this.stockObject.amount = null;
      }
      this.operation = newOperation;
      if (['add', 'remove'].includes(newOperation)) {
        this.stockObject.unit = this.initialStockObject.unit;
      }
    },
    fetchStockObject() {
      axios.get(this.stockUrl)
        .then((response) => {
          this.repositoryRowName = response.data.repository_row_name;
          this.initialStockObject = {...response.data.stock_value};
          this.stockObject = {...response.data.stock_value};
          this.updateStockUrl = response.data.stock_url

        })
        .catch(() => {
          HelperModule.flashAlertMsg(I18n.t('general.error'), 'danger');
        });
    },
    validateStockObject() {
      const newErrors = {};
      if (!this.stockObject.unit) { newErrors.unit = I18n.t('repository_stock_values.manage_modal.unit_error'); }
      if (!this.stockObject.amount) { newErrors.amount = I18n.t('repository_stock_values.manage_modal.amount_error'); }
      if (this.stockObject.reminder_enabled && !this.stockObject.low_stock_treshold) { newErrors.tresholdAmount = I18n.t('repository_stock_values.manage_modal.amount_error'); }
      if (this.stockObject.comment && this.stockObject.comment.length > 255) { newErrors.comment = I18n.t('repository_stock_values.manage_modal.comment_limit'); }
      this.errors = newErrors;
      return newErrors;
    },

    saveStockValue() {
      this.validateStockObject();

      if (this.isSaving || !this.isValid) return;

      this.isSaving = true;

      axios.post(this.updateStockUrl, {
        repository_stock_value: {
          unit_item_id: this.stockObject.unit,
          amount: this.newAmount,
          comment: this.stockObject.comment,
          low_stock_threshold: this.stockObject.reminder_enabled ? this.stockObject.low_stock_treshold : null
        },
        operator: this.operation,
        change_amount: Math.abs(new Decimal(this.stockObject.amount))
      })
        .then((result) => {
          this.isSaving = false;
          this.$emit('updateStock', result.data.data);
        })
        .catch((error) => {
          this.isSaving = false;
          HelperModule.flashAlertMsg(I18n.t('general.error'), 'danger');
        });
    }
  }
};
</script>
