<template>
  <div class="mb-6">
    <label class="sci-label">{{ filter.label }}</label>
    <div class="flex items-center gap-5">
      <DateTimePicker
        @change="updateDateFrom"
        :placeholder="i18n.t('From')"
        :dateOnly="true"
        :selectorId="`DatePicker${filter.key}`"
      />
      <DateTimePicker
        @change="updateDateTo"
        :placeholder="i18n.t('To')"
        :dateOnly="true"
        :selectorId="`DatePickerTo${filter.key}`"
      />
    </div>
  </div>
</template>

<script>
  import DateTimePicker from '../../date_time_picker.vue'

  export default {
    name: 'DateRangeFilter',
    props: {
      filter: { type: Object, required: true }
    },
    components: { DateTimePicker },
    data() {
      return {
        dateFrom: null,
        dateTo: null
      }
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
  }
</script>
