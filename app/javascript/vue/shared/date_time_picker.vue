<template>
  <div class="date-time-picker">
    <DatePicker v-if="!timeOnly" @change="updateDate" :selectorId="`${this.selectorId}_Date`" :defaultValue="defaultValue" />
    <TimePicker v-if="!dateOnly" @change="updateTime" :selectorId="`${this.selectorId}_Time`" :defaultValue="getTime(defaultValue)" />
  </div>
</template>

<script>
  import TimePicker from './time_picker.vue'
  import DatePicker from './date_picker.vue'

  export default {
    name: 'DateTimePicker',
    props: {
      dateOnly: { type: Boolean, default: false },
      timeOnly: { type: Boolean, default: false },
      selectorId: { type: String, required: true },
      defaultValue: {type: Date, required: false }
    },
    data() {
      return {
        date: '',
        time: '',
        datetime: ''
      }
    },
    components: {
      TimePicker,
      DatePicker
    },
    methods: {
      updateDate(value) {
        this.date = value;
        this.updateDateTime();
      },
      getTime(dateTime) {
        return `${dateTime.getHours().toString().padStart(2, '0')}:${dateTime.getMinutes().toString().padStart(2, '0')}`
      },
      updateTime(value) {
        this.time = value;
        this.updateDateTime();
      },
      updateDateTime() {
        this.recalcTimestamp();
        this.$emit('change', this.datetime);
      },

      isValidTime() {
        return /^([0-9]|0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]$/.test(this.time);
      },
      isValidDate(date) {
        return (date instanceof Date) && !isNaN(date.getTime());
      },
      recalcTimestamp() {
        let date = this.timeOnly ? new Date() : this.date;
        if (this.isValidDate(date) && (this.dateOnly || this.isValidTime())) {
          if (this.dateOnly) {
            date.setHours(0);
            date.setMinutes(0);
          } else {
            date.setHours(this.time.split(':')[0]);
            date.setMinutes(this.time.split(':')[1]);
          }
          this.datetime = date
        } else {
          this.datetime = null;
        }
      }
    }
  }
</script>
