<template>
  <div @click.stop class="mb-6">
    <div class="flex flex-col">
      <label class="sci-label">{{ filter.label }}</label>
      <div class="w-full mb-2">
        <DateTimePicker
          :defaultValue="dateFrom"
          class="w-full"
          @change="updateDateFrom"
          @cleared="updateDateFrom"
          :clearable="true"
          :placeholder="i18n.t('From')"
          :dateOnly="true"
          :selectorId="`DatePicker${filter.key}`"
        />
      </div>
      <div class="w-full">
        <DateTimePicker
        :defaultValue="dateTo"
          class="w-full"
          @change="updateDateTo"
          @cleared="updateDateTo"
          :clearable="true"
          :placeholder="i18n.t('To')"
          :dateOnly="true"
          :selectorId="`DatePickerTo${filter.key}`"
        />
      </div>
    </div>
  </div>
</template>

<script>
import DateTimePicker from '../../date_time_picker.vue';

export default {
  name: 'DateRangeFilter',
  props: {
    filter: { type: Object, required: true },
    values: { type: Object, required: true }
  },
  components: { DateTimePicker },
  data() {
    return {
      dateFrom: this.values[`${this.filter.key}_from`],
      dateTo: this.values[`${this.filter.key}_to`]
    };
  },
  methods: {
    updateDateFrom(value) {
      this.dateFrom = value;
      this.updateFilter();
    },
    updateDateTo(value) {
      this.dateTo = value;
      this.updateFilter();
    },
    updateFilter() {
      this.$emit('update', { key: `${this.filter.key}_from`, value: this.dateFrom });
      this.$emit('update', { key: `${this.filter.key}_to`, value: this.dateTo });
    }
  }
};
</script>
