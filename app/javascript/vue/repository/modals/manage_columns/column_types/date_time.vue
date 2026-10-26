<template>
  <div class="flex flex-col gap-4">
    <div class="flex items-center gap-2">
      <span class="sci-checkbox-container">
        <input type="checkbox" v-model="range" :disabled="!!column" class="sci-checkbox" id="date-time-range" />
        <span class="sci-checkbox-label"></span>
      </span>
      <label for="date-time-range" class="sci-label">{{ i18n.t('libraries.manange_modal_column.datetime_type.range_label') }}</label>
    </div>
    <template v-if="remindersSupported">
      <div class="flex items-center gap-2">
        <span class="sci-checkbox-container">
          <input type="checkbox" v-model="reminderEnabled" :disabled="range" class="sci-checkbox" id="date-time-reminder" />
          <span class="sci-checkbox-label"></span>
        </span>
        <label for="date-time-reminder" class="sci-label">{{ i18n.t('libraries.manange_modal_column.datetime_type.reminder') }}</label>
      </div>
      <div v-if="reminderEnabled" class="flex flex-col gap-2">
        <hr class="my-0">
        <div class="flex items-center gap-2">
          <label class="sci-label shrink-0">{{ i18n.t('libraries.manange_modal_column.datetime_type.remind') }}</label>
          <InputField
            class="!w-32"
            v-model="reminderValue"
            isNumber
            :placeholder="i18n.t('libraries.manange_modal_column.datetime_type.enter_amount')"
          />
          <SelectDropdown
            class="!w-32"
            :value="reminderUnit"
            :options="reminderUnitOptions"
            @change="reminderUnit = $event"
          />
          <span class="shrink-0">{{ i18n.t('libraries.manange_modal_column.datetime_type.before_set_date') }}</span>
        </div>
        <label class="sci-label">{{ i18n.t('libraries.manange_modal_column.datetime_type.reminder_message') }}</label>
        <InputField
          v-model="reminderMessage"
          :placeholder="i18n.t('libraries.manange_modal_column.datetime_type.enter_reminder_message')"
        />
      </div>
    </template>
  </div>
</template>

<script>
/* global GLOBAL_CONSTANTS */
import InputField from '../../../../shared/input_field.vue';
import SelectDropdown from '../../../../shared/select_dropdown.vue';

export default {
  name: 'DateTimeColumnType',
  components: { InputField, SelectDropdown },
  props: {
    column: { type: Object, default: null },
    kind: { type: String, required: true } // 'date' | 'time' | 'datetime'
  },
  data() {
    const metadata = this.column?.cellRendererParams?.metadata || {};
    return {
      range: !!this.column && /RangeValue$/.test(this.column.cellRendererParams.columnDataType),
      reminderEnabled: !!metadata.reminder_value,
      reminderValue: String(metadata.reminder_value || GLOBAL_CONSTANTS.REPOSITORY_DATETIME_REMINDER_PRESET),
      reminderUnit: metadata.reminder_unit || (60 * 60 * 24).toString(), // defaults to 1 day unit
      reminderMessage: metadata.reminder_message || ''
    };
  },
  watch: {
    range(newValue) {
      if (newValue) this.reminderEnabled = false;
    }
  },
  computed: {
    remindersSupported() {
      return this.kind !== 'time' && GLOBAL_CONSTANTS.STOCK_MANAGEMENT_ENABLED;
    },
    reminderUnitOptions() {
      return [
        [(60 * 60 * 24).toString(), this.i18n.t('libraries.manange_modal_column.datetime_type.days')],
        [(60 * 60 * 24 * 7).toString(), this.i18n.t('libraries.manange_modal_column.datetime_type.weeks')],
        [(60 * 60 * 24 * 28).toString(), this.i18n.t('libraries.manange_modal_column.datetime_type.months')]
      ];
    }
  },
  methods: {
    valid() {
      if (!this.remindersSupported || !this.reminderEnabled) return true;

      const value = parseInt(this.reminderValue, 10);
      if (Number.isNaN(value) || value < 1 || value > GLOBAL_CONSTANTS.MAX_NUMBER_OF_REMINDER_WEEKS) return false;

      return this.reminderMessage.length <= GLOBAL_CONSTANTS.NAME_MAX_LENGTH;
    },
    payload() {
      const payload = { range: this.range };
      if (this.remindersSupported) {
        payload.reminder_value = this.reminderEnabled ? this.reminderValue : '';
        payload.reminder_unit = this.reminderEnabled ? this.reminderUnit : '';
        payload.reminder_message = this.reminderEnabled ? this.reminderMessage : '';
      }
      return payload;
    }
  }
};
</script>
