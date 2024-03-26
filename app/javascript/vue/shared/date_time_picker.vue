<template>
  <div class="date-time-picker grow" :class="`size-${size}`" >
    <VueDatePicker
      ref="datetimePicker"
      :class="{
        'only-time': mode == 'time',
      }"
      @closed="closedHandler"
      @cleared="clearedHandler"
      v-model="compDatetime"
      :teleport="teleport"
      :no-today="true"
      :clearable="clearable"
      :format="format"
      :month-change-on-scroll="false"
      :six-weeks="true"
      :auto-apply="true"
      :partial-flow="true"
      :markers="markers"
      week-start="0"
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
    defaultValue: { type: Date, required: false },
    placeholder: { type: String },
    standAlone: { type: Boolean, default: false, required: false },
    dateClassName: { type: String, default: '' },
    timeClassName: { type: String, default: '' },
    disabled: { type: Boolean, default: false },
    customIcon: { type: String },
    size: { type: String, default: 'xs' }
  },
  data() {
    return {
      manualUpdate: false,
      datetime: this.defaultValue,
      time: null,
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
    if (this.defaultValue) {
      this.time = {
        hours: this.defaultValue.getHours(),
        minutes: this.defaultValue.getMinutes()
      };
    }
  },
  components: {
    VueDatePicker
  },
  watch: {
    defaultValue() {
      this.datetime = this.defaultValue;
      if (this.defaultValue instanceof Date) {
        this.time = {
          hours: this.defaultValue.getHours(),
          minutes: this.defaultValue.getMinutes()
        };
      }
    },
    datetime() {
      if (this.mode === 'time') {
        this.time = null;

        if (this.datetime instanceof Date) {
          this.time = {
            hours: this.datetime.getHours(),
            minutes: this.datetime.getMinutes()
          };
        }

        return;
      }

      if (this.manualUpdate) {
        this.manualUpdate = false;
        return;
      }

      if (this.datetime == null) {
        this.$emit('cleared');
      }

      if (this.defaultValue !== this.datetime) {
        this.$emit('change', this.datetime);
      }
    },
    time() {
      if (this.manualUpdate) {
        this.manualUpdate = false;
        return;
      }

      if (this.mode !== 'time') return;

      let newDate;

      if (this.time) {
        newDate = new Date();
        newDate.setHours(this.time.hours);
        newDate.setMinutes(this.time.minutes);
      } else {
        newDate = {
          hours: null,
          minutes: null
        };
        this.$emit('cleared');
      }

      if (this.defaultValue !== newDate) {
        this.$emit('change', newDate);
      }
    }
  },
  computed: {
    compDatetime: {
      get() {
        if (this.mode === 'time') {
          return this.time;
        }
        return this.datetime;
      },
      set(val) {
        if (this.mode === 'time') {
          this.time = val;
        } else {
          this.datetime = val;
        }
      }
    },
    format() {
      if (this.mode === 'time') return 'HH:mm';
      if (this.mode === 'date') return document.body.dataset.datetimePickerFormatVue;
      return `${document.body.dataset.datetimePickerFormatVue} HH:mm`;
    }
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
    }
  }
};
</script>
