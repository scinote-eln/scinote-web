<template>
  <div class="flex gap-2">
    <SelectDropdown class="!w-40"
                    :options="dateOptions"
                    :value="selectedOption"
                    @change="(v) => {selectedOption = v}" />
    <div class="grow">
      <DateTimePicker
        v-if="selectedOption === 'on'"
        @change="setOn"
        mode="date"
        size="mb"
        placeholder="Enter date"
        :defaultValue="date.on"
        :clearable="true"/>
      <DateTimePicker
        v-if="selectedOption === 'custom'"
        @change="setFrom"
        class="mb-2"
        mode="date"
        size="mb"
        placeholder="From date"
        :defaultValue="date.from"
        :clearable="true"/>
      <DateTimePicker
        v-if="selectedOption === 'custom'"
        @change="setTo"
        mode="date"
        size="mb"
        placeholder="To date"
        :defaultValue="date.to"
        :clearable="true"/>
    </div>
  </div>
</template>

<script>
import SelectDropdown from '../../shared/select_dropdown.vue';
import DateTimePicker from '../../shared/date_time_picker.vue';

export default {
  name: 'DateFilter',
  props: {
    date: {
      type: Object,
      required: true
    }
  },
  components: {
    SelectDropdown,
    DateTimePicker
  },
  watch: {
    selectedOption() {
      const today = new Date();
      const yesterday = new Date(new Date().setDate(today.getDate() - 1));
      const weekDay = today.getDay();
      const monday = new Date(new Date()
        .setDate(today.getDate() - weekDay - (weekDay === 0 ? 6 : -1)));
      const lastWeekStart = new Date(monday.getTime() - (7 * 24 * 60 * 60 * 1000));
      const lastWeekEnd = new Date(lastWeekStart.getTime() + (6 * 24 * 60 * 60 * 1000));
      const firstMonthDay = new Date(today.getFullYear(), today.getMonth(), 1);
      const firstYearDay = new Date(today.getFullYear(), 0, 1);
      const lastYearEnd = new Date(today.getFullYear(), 0, 0);
      const lastYearStart = new Date(today.getFullYear() - 1, 0, 1);

      switch (this.selectedOption) {
        case 'today':
          this.newDate = {
            on: today, from: null, to: null, mode: 'today'
          };
          break;
        case 'yesterday':
          this.newDate = {
            on: yesterday, from: null, to: null, mode: 'yesterday'
          };
          break;
        case 'last_week':
          this.newDate = {
            on: null, from: lastWeekStart, to: lastWeekEnd, mode: 'last_week'
          };
          break;
        case 'this_month':
          this.newDate = {
            on: null, from: firstMonthDay, to: today, mode: 'this_month'
          };
          break;
        case 'this_year':
          this.newDate = {
            on: null, from: firstYearDay, to: today, mode: 'this_year'
          };
          break;
        case 'last_year':
          this.newDate = {
            on: null, from: lastYearStart, to: lastYearEnd, mode: 'last_year'
          };
          break;
        case 'on':
          this.newDate = {
            on: null, from: null, to: null, mode: 'on'
          };
          break;
        case 'custom':
          this.newDate = {
            on: null, from: null, to: null, mode: 'custom'
          };
          break;
        default:
          break;
      }

      this.$emit('change', this.newDate);
    }
  },
  data() {
    return {
      newDate: this.date,
      selectedOption: (this.date.mode || 'on'),
      dateOptions: [
        ['today', 'Today'],
        ['yesterday', 'Yesterday'],
        ['last_week', 'Last week'],
        ['this_month', 'This month'],
        ['this_year', 'This year'],
        ['last_year', 'Last year'],
        ['on', 'On'],
        ['custom', 'Custom']
      ]
    };
  },
  methods: {
    setOn(v) {
      this.newDate = {
        on: v, from: null, to: null, mode: 'on'
      };
      this.$emit('change', this.newDate);
    },
    setFrom(v) {
      this.newDate.mode = 'custom';
      this.newDate.on = null;
      this.newDate.from = v;
      this.$emit('change', this.newDate);
    },
    setTo(v) {
      this.newDate.mode = 'custom';
      this.newDate.on = null;
      this.newDate.to = v;
      this.$emit('change', this.newDate);
    }
  }
};
</script>
