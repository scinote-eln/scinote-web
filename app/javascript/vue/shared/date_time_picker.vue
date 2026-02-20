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
    defaultValue: { type: String, required: false },
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

      if (this.mode === 'time') {
        return `${this.value.hours.toString().padStart(2, '0')}:${this.value.minutes.toString().padStart(2, '0')}`
      }

      const time = ` ${this.value.getHours().toString().padStart(2, '0')}:${this.value.getMinutes().toString().padStart(2, '0')}`
      const date = `${this.value.getFullYear()}-${this.value.getMonth() + 1}-${this.value.getDate()}`;

      if (this.mode === 'date') {
        return date;
      } else {
        return `${date} ${time}`;
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
    initializeValue() {
      if (!this.defaultValue) return;

      if (this.mode === 'time') {
        // expects time in format of "[date] HH:mm"
        const [hours, minutes] = this.defaultValue.match(/(\d{2}:\d{2})/)[0].split(":").map(Number);

        this.value = { hours: hours, minutes: minutes, seconds: 0 }
      } else {
        this.value = new Date(this.defaultValue.replace(/([^!\s])-/g, '$1/'));
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
