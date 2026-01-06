<template v-if="this.initialized">
  <div class="date-time-picker grow" :class="`size-${size}`" :data-e2e="dataE2e">
    <VueDatePicker
      ref="datetimePicker"
      :class="{
        'only-time': mode == 'time',
        'no-border': noBorder,
      }"
      @closed="closedHandler"
      @cleared="clearedHandler"
      v-model="datetime"
      :teleport="teleport"
      :clearable="clearable"
      :monthChangeOnScroll="false"
      :sixWeeks="true"
      :disabled="disabled"
      :autoApply="true"
      :partialFlow="true"
      :markers="markers"
      :time-picker="mode === 'time'"
      :timezone="timezone"
      :weekStart="0"
      :hideInputIcon="noIcons"
      :time-config="{ enableTimePicker: mode !== 'date', startTime: { hours: 0, minutes: 0, seconds: 0 } }"
      :formats="{ input: format }"
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
import { VueDatePicker, TZDate } from '@vuepic/vue-datepicker';

export default {
  name: 'DateTimePicker',
  props: {
    mode: { type: String, default: 'datetime' },
    clearable: { type: Boolean, default: false },
    teleport: { type: Boolean, default: true },
    defaultValue: { type: Date, required: false },
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
    noBorder: { type: Boolean, default: false }
  },
  data() {
    return {
      initialized: false,
      manualUpdate: false,
      datetime: this.defaultValue,
      time: null,
      timezone: document.body.dataset.datetimePickerTimezone,
      markers: [
        {
          date: new Date(),
          type: 'dot',
          color: '#3B99FD'
        }
      ]
    };
  },
  components: {
    VueDatePicker
  },
  watch: {
    datetime() {
      if (!this.initialized) return;

      this.$emit('change', this.mode === 'time' ? this.timeToDate() : this.datetime);
    }
  },
  created() {
    this.$nextTick(() => {
      if (this.mode === 'date' && this.datetime) {
        // set date to date in users' timezone
        this.datetime = new TZDate(`${this.datetime.getMonth() + 1}-${this.datetime.getDate()}-${this.datetime.getFullYear()}`, this.timezone);
      }

      if (this.mode === 'time' && this.datetime) {
        this.datetime =  {
          hours: this.datetime.getHours(),
          minutes: this.datetime.getMinutes(),
          seconds: this.datetime.getSeconds()
        }
      }

      this.$nextTick(() => this.initialized = true);
    });
  },
  computed: {
    format() {
      if (this.mode === 'time') return 'HH:mm';
      if (this.mode === 'date') return document.body.dataset.datetimePickerFormatVue;
      return `${document.body.dataset.datetimePickerFormatVue} HH:mm`;
    },
  },
  mounted() {
    window.addEventListener('resize', this.close);
  },
  unmounted() {
    window.removeEventListener('resize', this.close);
  },
  methods: {
    close() {
      this.$refs.datetimePicker.closeMenu();
    },
    closedHandler() {
      this.$emit('closed');
    },
    clearedHandler() {
      this.$emit('cleared');
    },
    timeToDate() {
      if (!this.datetime || this.mode !== 'time') return;

      let timeDate = new Date();
      timeDate.setHours(this.datetime.hours);
      timeDate.setMinutes(this.datetime.minutes);

      return timeDate;
    }
  }
};
</script>
