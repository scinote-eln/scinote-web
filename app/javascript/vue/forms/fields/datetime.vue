<template>
  <div>
    <div v-if="range" class="flex items-center gap-4">
      <DateTimePicker
        @change="updateFromDate"
        :mode="mode"
        :clearable="true"
        :placeholder="i18n.t('forms.fields.from')"
        :class="{'error': !validValue}"
      />
      <DateTimePicker
        @change="updateToDate"
        :mode="mode"
        :clearable="true"
        :placeholder="i18n.t('forms.fields.to')"
        :class="{'error': !validValue}"
      />
    </div>
    <DateTimePicker
      v-else
      @change="updateDate"
      :mode="mode"
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
  methods: {
    updateDate(date) {
      this.value = date;
    },
    updateFromDate(date) {
      this.fromValue = date;
    },
    updateToDate(date) {
      this.toValue = date;
    }
  }
};
</script>
