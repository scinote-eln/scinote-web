<template>
  <div class="flex flex-col gap-2">
    <DateTimePicker :defaultValue="defaultStartDate" @closed="update" @change="updateStartDate" :mode="mode" :placeholder="placeholder" :clearable="true"/>
    <div v-if="range" class="w-0.5 h-3 bg-sn-grey mx-auto"></div> <!-- divider -->
    <DateTimePicker :defaultValue="defaultEndDate" @closed="update" v-if="range" @change="updateEndDate" :placeholder="placeholder" :mode="mode" :clearable="true"/>
    <div class="text-xs text-sn-delete-red" v-if="error">{{ error }}</div>
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
        error: null,
        defaultStartDate: null,
        defaultEndDate: null
      }
    },
    props: {
      mode: String,
      range: { type: Boolean, default: false },
      colVal: { type: Object, default: {} },
      colId: Number,
      updatePath: String,
      canEdit: { type: Boolean, default: false }
    },
    created() {
      if (this.range) {
        if (this.colVal.start_time?.datetime) this.startDate = new Date(this.colVal.start_time.datetime)
        if (this.colVal.end_time?.datetime) this.endDate = new Date(this.colVal.end_time.datetime)
      } else {
        if (this.colVal.datetime) this.startDate = new Date(this.colVal.datetime)
      }

      this.defaultStartDate = this.startDate;
      this.defaultEndDate = this.endDate;
    },
    computed: {
      value: {
        get () {
          if (this.range) {
            if (!(this.startDate instanceof Date) && !(this.endDate instanceof Date)) return null;

            return  {
                      start_time: this.formatDate(this.startDate),
                      end_time: this.formatDate(this.endDate)
                    };
          } else {
            if (!(this.startDate instanceof Date)) return null;

            return this.formatDate(this.startDate);
          }
        },
      },
      placeholder() {
        switch (this.mode) {
          case 'date':
            return this.i18n.t('repositories.item_card.repository_date_value.placeholder');
          case 'time':
            return this.i18n.t('repositories.item_card.repository_time_value.placeholder');
          case 'datetime':
            return this.i18n.t('repositories.item_card.repository_date_time_value.placeholder');
        }
      }
    },
    methods: {
      updateStartDate(date) {
        this.startDate = date;
        if (!(this.startDate instanceof Date)) this.update();
      },
      updateEndDate(date) {
        this.endDate = date;
        if (!(this.endDate instanceof Date)) this.update();
      },
      validateValue() {
        this.error = null;
        // Date is not changed
        if (this.defaultStartDate == this.startDate && this.defaultEndDate == this.endDate) return false;

        if (this.range) {
          // Both empty
          if (!(this.startDate instanceof Date) && !(this.endDate instanceof Date)) return true;

          // One empty
          if (!(this.startDate instanceof Date) || !(this.endDate instanceof Date)) {
            this.error = this.i18n.t('repositories.item_card.date_time.errors.not_valid_range')
            return false;
          }

          // Start date is after end date
          if (this.startDate > this.endDate) {
            this.error = this.i18n.t('repositories.item_card.date_time.errors.not_valid_range')
            return false;
          }
        }

        return true
      },
      update() {
        const params = {}

        if (!this.validateValue()) return;

        params[this.colId] = this.value
        $.ajax({
          method: 'PUT',
          url: this.updatePath,
          dataType: 'json',
          data: { repository_cells: params },
          success: () => {
            this.defaultStartDate = this.startDate;
            this.defaultEndDate = this.endDate;
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
