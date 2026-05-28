<template>
  <div class="date-time-picker grow" :class="`size-${size}`" :data-e2e="dataE2e">
    <VueDatePicker
      ref="datetimePicker"
      :class="{
        'only-time': mode == 'time',
        'no-border': noBorder,
      }"
      @closed="closedHandler"
      @cleared="clearedHandler"
      @update:model-value="changeHandler"
      v-model="value"
      :teleport="teleport"
      :no-today="true"
      :clearable="clearable"
      :format="format"
      :month-change-on-scroll="false"
      :six-weeks="true"
      :disabled="disabled"
      :auto-apply="true"
      :partial-flow="true"
      :markers="markers"
      :range="range"
      :start-time="{ hours: 0, minutes: 0, seconds: 0 }"
      week-start="0"
      :hide-input-icon="noIcons"
      :enable-time-picker="mode == 'datetime'"
      :time-picker="mode == 'time'"
      :placeholder="placeholder" >
        <template #arrow-right>
            <img class="slot-icon" src="/images/calendar/navigate_next.svg"/>
        </template>
        <template #arrow-left>
            <img class="slot-icon" src="/images/calendar/navigate_before.svg"/>
        </template>
        <template v-if="customIcon" #input-icon>
            <i :class="customIcon + ' -ml-1'"></i>
        </template>
        <template v-else-if="mode == 'time'" #input-icon>
            <img class="input-slot-image" src="/images/calendar/clock.svg"/>
        </template>
        <template v-else #input-icon>
            <img class="input-slot-image" src="/images/calendar/calendar.svg"/>
        </template>
        <template #clock-icon>
            <img class="slot-icon" src="/images/calendar/clock.svg"/>
        </template>
        <template #calendar-icon>
            <img class="slot-icon" src="/images/calendar/calendar.svg"/>
        </template>
        <template #arrow-up>
            <img class="slot-icon" src="/images/calendar/up.svg"/>
        </template>
        <template #arrow-down>
            <img class="slot-icon" src="/images/calendar/down.svg"/>
        </template>
    </VueDatePicker>
  </div>
</template>

<script>
import VueDatePicker from '@vuepic/vue-datepicker';

export default {
  name: 'DateTimePicker',
  props: {
    mode: { type: String, default: 'datetime' },
    clearable: { type: Boolean, default: false },
    teleport: { type: Boolean, default: true },
    defaultValue: { type: [String, Array], required: false },
    placeholder: { type: String },
    standAlone: { type: Boolean, default: false, required: false },
    dateClassName: { type: String, default: '' },
    timeClassName: { type: String, default: '' },
    disabled: { type: Boolean, default: false },
    customIcon: { type: String },
    size: { type: String, default: 'xs' },
    dataE2e: { type: String, default: '' },
    valueType: { type: String, default: 'object' },
    noIcons: { type: Boolean, default: false },
    noBorder: { type: Boolean, default: false },
    range: { type: Boolean, default: false }
  },
  data() {
    return {
      value: null,
      markers: [
        {
          date: new Date(),
          type: 'dot',
          color: '#3B99FD'
        }
      ]
    };
  },
  created() {
    this.initializeValue();
  },
  components: {
    VueDatePicker
  },
  watch: {
    defaultValue() {
      this.initializeValue();
    }
  },
  computed: {
    format() {
      if (this.mode === 'time') return 'HH:mm';
      if (this.mode === 'date') return document.body.dataset.datetimePickerFormatVue;
      return `${document.body.dataset.datetimePickerFormatVue} HH:mm`;
    },
    stringValue() {
      if (this.value === null) return '';
      if (this.range) {
        const start = this.value[0];
        const end = this.value[1];

        if (!start || !end) return '';

        if (this.mode === 'time') {
          const startTime = `${start.hours.toString().padStart(2, '0')}:${start.minutes.toString().padStart(2, '0')}`;
          const endTime = `${end.hours.toString().padStart(2, '0')}:${end.minutes.toString().padStart(2, '0')}`;

          return [startTime, endTime];
        }

        const startDate = this.extractDateString(start);
        const endDate = this.extractDateString(end);

        if (this.mode === 'date') {
          return [startDate, endDate];
        } else {
          const startTime = this.extractTimeString(start);
          const endTime = this.extractTimeString(end);

          return [`${startDate} ${startTime}`, `${endDate} ${endTime}`];
        }
      } else {
        if (this.mode === 'time') {
          return `${this.value.hours.toString().padStart(2, '0')}:${this.value.minutes.toString().padStart(2, '0')}`
        }

        const time = this.extractTimeString(this.value);
        const date = this.extractDateString(this.value);

        if (this.mode === 'date') {
          return this.extractDateString(this.value);
        } else {
          return `${this.extractDateString(this.value)} ${this.extractTimeString(this.value)}`;
        }
      }
    }
  },
  mounted() {
    window.addEventListener('resize', this.close);
  },
  unmounted() {
    window.removeEventListener('resize', this.close);
  },
  methods: {
    extractTimeString(date) {
      return `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
    },
    extractDateString(date) {
      return `${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()}`;
    },
    initializeValue() {
      if (!this.defaultValue) return;
      
      if (this.range) {
        const start = this.defaultValue[0];
        const end = this.defaultValue[1];
        if (!start || !end) return '';

        this.value = [];
        if (this.mode === 'time') {
          // expects time in format of "[date] HH:mm"
          const [startHours, startMinutes] = start.match(/(\d{2}:\d{2})/)[0].split(":").map(Number);
          const [endHours, endMinutes] = end.match(/(\d{2}:\d{2})/)[0].split(":").map(Number);

          this.value[0] = { hours: startHours, minutes: startMinutes, seconds: 0 }
          this.value[1] = { hours: endHours, minutes: endMinutes, seconds: 0 }
        } else {
          this.value[0] = new Date(start.replace(/([^!\s])-/g, '$1/'));
          this.value[1] = new Date(end.replace(/([^!\s])-/g, '$1/'));
        }
      } else {
        if (this.mode === 'time') {
          // expects time in format of "[date] HH:mm"
          const [hours, minutes] = this.defaultValue.match(/(\d{2}:\d{2})/)[0].split(":").map(Number);

          this.value = { hours: hours, minutes: minutes, seconds: 0 }
        } else {
          this.value = new Date(this.defaultValue.replace(/([^!\s])-/g, '$1/'));
        }
      }
    },
    close() {
      this.$refs.datetimePicker.closeMenu();
    },
    changeHandler(value) {
      this.value = value;
      this.$emit('change', this.stringValue);
    },
    closedHandler() {
      this.$emit('closed');
    },
    clearedHandler() {
      this.$emit('cleared');
    }
  }
};
</script>
