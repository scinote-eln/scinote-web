<template>
  <div class='relative'>
    <template v-if="range">
      <div class="flex lg:items-center gap-x-4 gap-y-2 flex-col lg:flex-row">
        <DateTimePicker
          @change="updateFromDate"
          :mode="mode"
          :defaultValue="fromValue"
          :clearable="true"
          :disabled="fieldDisabled"
          :placeholder="fieldDisabled ? '' : i18n.t('forms.fields.from')"
          class="grow"
          :class="{'error': !validValue}"
          :dataE2e="`e2e-TP-${dataE2e}-dateTimeFrom`"
          ref="startDatepicker"
        />
        <span class="tw-hidden lg:block">-</span>
        <DateTimePicker
          @change="updateToDate"
          :defaultValue="toValue"
          :mode="mode"
          :disabled="fieldDisabled"
          :clearable="true"
          :placeholder="fieldDisabled ? '' : i18n.t('forms.fields.to')"
          class="grow"
          :class="{'error': !validValue}"
          :dataE2e="`e2e-TP-${dataE2e}-dateTimeTo`"
          ref="endDatepicker"
        />
      </div>
      <span v-if="!validFutureDate" class="text-xs text-sn-delete-red block absolute -bottom-3.5">
        {{ i18n.t('forms.fields.not_valid_future_date') }}
      </span>
      <span v-else-if="!validValue" class="text-xs text-sn-delete-red block absolute -bottom-3.5">
        {{ i18n.t('forms.fields.not_valid_range') }}
      </span>
    </template>
    <template v-else>
      <DateTimePicker
        @change="updateDate"
        :defaultValue="value"
        :mode="mode"
        :disabled="fieldDisabled"
        :clearable="true"
        :placeholder="fieldDisabled ? '' : i18n.t(`forms.fields.add_${mode}`)"
         :class="{'error': !validFutureDate}"
        :dataE2e="`e2e-TP-${dataE2e}-dateTime`"
      />
      <span v-if="!validFutureDate" class="text-xs text-sn-delete-red block absolute -bottom-3.5">
        {{ i18n.t('forms.fields.not_valid_future_date') }}
      </span>
    </template>
  </div>
</template>

<script>
import fieldMixin from './field_mixin';
import DateTimePicker from '../../shared/date_time_picker.vue';

export default {
  name: 'DatetimeField',
  mixins: [fieldMixin],
  props: {
    dataE2e: {
      type: String,
      default: ''
    }
  },
  components: {
    DateTimePicker
  },
  data() {
    return {
      value: null,
      fromValue: null,
      toValue: null
    };
  },
  created() {
    const field_value = this.field.field_value;
    const mainDateStr = field_value?.datetime || field_value?.date;
    if (mainDateStr) {
      this.value = mainDateStr;
      this.fromValue = mainDateStr;
    }

    const toDateStr = field_value?.datetime_to || field_value?.date_to;
    if (toDateStr) {
      this.toValue = toDateStr;
    }
  },
  computed: {
    mode() {
      return this.field.attributes.data.time ? 'datetime' : 'date';
    },
    range() {
      return this.field.attributes.data.range;
    },
    currentDatetime() {
      return new Date(this.field.attributes.current_datetime);
    },
    validValue() {
      if (this.fieldDisabled) return true;
      if (!this.validFutureDate) return false;

      if (this.range) {
        return Boolean(this.fromValue) === Boolean(this.toValue) &&
          (
            // rangeIsValid needs to be an outside method, as using $refs breaks computed value reactivity
            !this.fromValue || !this.toValue || this.rangeIsValid()
          );
      }

      return true;
    },
    validFutureDate() {
      if (!this.currentDatetime) return true;

      if (this.range) {
        return (!this.fromValue || new Date(this.fromValue) <= this.currentDatetime) &&
               (!this.toValue || new Date(this.toValue) <= this.currentDatetime);
      }

      return !this.value || new Date(this.value) <= this.currentDatetime;
    }
  },
  watch: {
    marked_as_na() {
      if (this.marked_as_na) {
        this.value = null;
        this.fromValue = null;
        this.toValue = null;
      }
    }
  },
  methods: {
    updateDate(date) {
      this.value = date;
      if (this.validFutureDate) {
        this.$emit('save', this.value);
      }
    },
    updateFromDate(date) {
      this.fromValue = date;
      if (this.validValue) {
        this.$emit('save', [this.fromValue, this.toValue]);
      }
    },
    updateToDate(date) {
      this.toValue = date;
      if (this.validValue) {
        this.$emit('save', [this.fromValue, this.toValue]);
      }
    },
    rangeIsValid() {
      return this.$refs.endDatepicker?.value >= this.$refs.startDatepicker?.value
    }
  }
};
</script>
