<template>
  <div class="date-time-picker grow">
    <VueDatePicker
      v-if="mode == 'datetime'"
      v-model="datetime"
      :teleport="teleport"
      text-input
      :clearable="clearable"
      time-picker-inline
      :format="dateTimeFormat"
      :placeholder="placeholder" ></VueDatePicker>

    <VueDatePicker
      v-if="mode == 'date'"
      v-model="datetime"
      :teleport="teleport"
      :clearable="clearable"
      text-input
      :format="dateFormat"
      :enable-time-picker="false"
      :placeholder="placeholder" ></VueDatePicker>

    <VueDatePicker
      v-if="mode == 'time'"
      v-model="time"
      :teleport="teleport"
      :clearable="clearable"
      text-input
      :format="timeFormat"
      time-picker
      :placeholder="placeholder" ></VueDatePicker>
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
      placeholder: { type: String }
    },
    data() {
      return {
        datetime: this.defaultValue,
        time: null
      }
    },
    created() {
      if (this.defaultValue) {
        this.time = {
                      hours: this.defaultValue.getHours(),
                      minutes:this.defaultValue.getMinutes(),
                    }
      }
    },
    components: {
      VueDatePicker
    },
    watch: {
      defaultValue: function () {
        this.datetime = this.defaultValue;
        this.time = {
          hours: this.defaultValue ? this.defaultValue.getHours() : 0,
          minutes: this.defaultValue ? this.defaultValue.getMinutes() : 0
        }
      },
      datetime: function () {
        if (this.mode == 'time') {
          this.time = {
            hours: this.datetime ? this.datetime.getHours() : 0,
            minutes: this.datetime ? this.datetime.getMinutes() : 0
          }
          return
        }

        if ( this.datetime == null) {
          this.$emit('cleared');
        }

        if (this.defaultValue != this.datetime) {
          this.$emit('change', this.datetime);
        }
      },
      time: function () {
        if (this.mode != 'time') return;

        let newDate;

        if (this.time) {
          newDate = new Date();
          newDate.setHours(this.time.hours);
          newDate.setMinutes(this.time.minutes);
        } else {
          newDate = null;
          this.$emit('cleared');
        }

        if (this.defaultValue != newDate) {
          this.$emit('change', newDate);
        }
      }
    },
    computed: {
      dateTimeFormat() {
        return `${document.body.dataset.datetimePickerFormatVue} HH:mm`
      },
      dateFormat() {
        return document.body.dataset.datetimePickerFormatVue
      },
      timeFormat() {
        return 'HH:mm'
      },
    }
  }
</script>
