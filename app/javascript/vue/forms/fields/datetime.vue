<template>
  <div>
    <div v-if="range" class="flex items-center gap-4">
      <DateTimePicker
        @change="updateFromDate"
        :mode="mode"
        :defaultValue="fromValue"
        :clearable="true"
        :disabled="fieldDisabled"
        :placeholder="i18n.t('forms.fields.from')"
        :class="{'error': !validValue}"
      />
      <DateTimePicker
        @change="updateToDate"
        :defaultValue="toValue"
        :mode="mode"
        :disabled="fieldDisabled"
        :clearable="true"
        :placeholder="i18n.t('forms.fields.to')"
        :class="{'error': !validValue}"
      />
    </div>
    <DateTimePicker
      v-else
      @change="updateDate"
      :defaultValue="value"
      :mode="mode"
      :disabled="fieldDisabled"
      :clearable="true"
      :placeholder="i18n.t(`forms.fields.add_${mode}`)"
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
        return !this.fromValue || !this.toValue || this.fromValue <= this.toValue;
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
      this.value = date;
      this.$emit('save', this.value);
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
    }
  }
};
</script>
