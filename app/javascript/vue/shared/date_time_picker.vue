<template>
  <div class="date-time-picker grow">
    <VueDatePicker
      v-if="mode == 'datetime'"
      v-model="datetime"
      :teleport="true"
      :format="dateTimeFormat"
      :placeholder="placeholder" ></VueDatePicker>

    <VueDatePicker
      v-if="mode == 'date'"
      v-model="datetime"
      :teleport="true"
      :format="dateFormat"
      :enable-time-picker="false"
      :placeholder="placeholder" ></VueDatePicker>

    <VueDatePicker
      v-if="mode == 'time'"
      v-model="datetime"
      :teleport="true"
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
      defaultValue: { type: Date, required: false },
      placeholder: { type: String }
    },
    data() {
      return {
        datetime: this.defaultValue
      }
    },
    watch: {
      defaultValue: function () {
        this.datetime = this.defaultValue;
      }
    },
    components: {
      VueDatePicker
    },
    watch: {
      datetime: function () {
        if ( this.datetime == null) {
          this.$emit('cleared');
        }

        if (this.defaultValue != this.datetime) {
          let newDate = this.datetime;
          if (this.mode == 'time') {
            newDate = new Date();
            newDate.setHours(this.datetime.hours);
            newDate.setMinutes(this.datetime.minutes);
          }
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
      }
    }
  }
</script>
