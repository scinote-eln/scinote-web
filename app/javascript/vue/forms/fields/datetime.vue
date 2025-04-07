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
        />
      </div>
      <span v-if="!validValue" class="text-xs text-sn-delete-red block absolute -bottom-3.5">
        {{ i18n.t('forms.fields.not_valid_range') }}
      </span>
    </template>
    <DateTimePicker
      v-else
      @change="updateDate"
      :defaultValue="value"
      :mode="mode"
      :disabled="fieldDisabled"
      :clearable="true"
      :placeholder="fieldDisabled ? '' : i18n.t(`forms.fields.add_${mode}`)"
    />
  </div>
</template>

<script>
import fieldMixin from './field_mixin';
import DateTimePicker from '../../shared/date_time_picker.vue';

export default {
  name: 'DatetimeField',
  mixins: [fieldMixin],
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
    if (this.field.field_value?.datetime) {
      this.value = new Date(this.field.field_value.datetime);
      this.fromValue = new Date(this.field.field_value.datetime);
    }
    if (this.field.field_value?.datetime_to) {
      this.toValue = new Date(this.field.field_value.datetime_to);
    }
  },
  computed: {
    mode() {
      return this.field.attributes.data.time ? 'datetime' : 'date';
    },
    range() {
      return this.field.attributes.data.range;
    },
    validValue() {
      if (this.range) {
        return Boolean(this.fromValue) === Boolean(this.toValue) && (!this.fromValue || !this.toValue || this.fromValue <= this.toValue);
      }
      return this.value;
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
      this.value = this.stripTimeIfDate(date);
      this.$emit('save', this.value);
    },
    updateFromDate(date) {
      this.fromValue = this.stripTimeIfDate(date);
      if (this.validValue) {
        this.$emit('save', [this.fromValue, this.toValue]);
      }
    },
    updateToDate(date) {
      this.toValue = this.stripTimeIfDate(date);
      if (this.validValue) {
        this.$emit('save', [this.fromValue, this.toValue]);
      }
    },
    stripTimeIfDate(date) {
      if (this.mode !== 'date') return date;

      return new Date(Date.UTC(
        date.getFullYear(),
        date.getMonth(),
        date.getDate(),
        0, 0, 0, 0
      ));
    }
  }
};
</script>
