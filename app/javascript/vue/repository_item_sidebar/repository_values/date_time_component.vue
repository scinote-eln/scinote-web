<template>
  <div class="flex flex-col gap-2">
    <DateTimePicker :defaultValue="defaultStartDate" @change="updateStartDate" :mode="mode" :clearable="true"
                    :readonly="!canEdit"/>
    <DateTimePicker :defaultValue="defaultEndDate" v-if="range" @change="updateEndDate" :mode="mode" :clearable="true"
                    :readonly="!canEdit"/>
  </div>
</template>

<script>
  import DateTimePicker from '../../shared/date_time_picker.vue';
  import Reminder from '../reminder.vue';

  export default {
    name: 'DateTimeComponent',
    components: {
      DateTimePicker,
      Reminder
    },
    data() {
      return {
        startDate: null,
        endDate: null,
      }
    },
    props: {
      mode: String,
      range: { type: Boolean, default: false },
      colVal: { type: Object, default: {} },
      colId: Number,
      updatePath: String,
      canEdit: { type: Boolean, default: false },
    },
    created() {
      if (this.range) {
        if (this.colVal.start_time?.datetime) this.startDate = new Date(this.colVal.start_time.datetime)
        if (this.colVal.end_time?.datetime) this.endDate = new Date(this.colVal.end_time.datetime)
      } else {
        if (this.colVal.datetime) this.startDate = new Date(this.colVal.datetime)
      }
    },
    watch: {
    },
    computed: {
      defaultStartDate() {
        if (this.range && this.colVal.start_time) {
          return new Date(this.colVal.start_time.datetime)
        } else if (this.colVal.datetime) {
          return new Date(this.colVal.datetime)
        }
      },
      defaultEndDate() {
        if (this.range && this.colVal.end_time) {
          return new Date(this.colVal.end_time.datetime)
        }
      },
      value: {
        get () {
          if (this.range) {
            if (!this.startDate && !this.endDate) return null;
            if (!(this.startDate instanceof Date)) return null;
            if (!(this.endDate instanceof Date)) return null;

            return  {
                      start_time: this.formatDate(this.startDate),
                      end_time: this.formatDate(this.endDate)
                    }
          } else {
            if (!(this.startDate instanceof Date)) return null;
            return this.formatDate(this.startDate)
          }
        },
      },
    },
    methods: {
      updateStartDate(date) {
        this.startDate = date
        this.update()
      },
      updateEndDate(date) {
        this.endDate = date
        this.update()
      },
      update() {
        const params = {}
        params[this.colId] = this.value
        $.ajax({
          method: 'PUT',
          url: this.updatePath,
          dataType: 'json',
          data: { repository_cells: params },
          success: () => {
            if ($('.dataTable')[0]) $('.dataTable').DataTable().ajax.reload(null, false);
          }
        });
      },
      formatDate(date) {
        if (!(date instanceof Date)) return null;

        const y = date.getFullYear();
        const m = date.getMonth() + 1;
        const d = date.getDate();
        const hours = date.getHours();
        const mins = date.getMinutes();
        return `${y}/${m}/${d} ${hours}:${mins}`;
      },
    }
  }
</script>
