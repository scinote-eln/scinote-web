<template>
  <div class="flex gap-1">
    <div class="text-sm font-bold truncate" :title="colName">
      {{ colName }}
    </div>
    <div v-if="colVal.reminder" class="bg-sn-alert-passion w-1.5 h-1.5 min-w-[0.375rem] min-h-[0.375rem] rounded hover:cursor-pointer" :title="colVal.reminder_text"></div>
  </div>
  <div class="flex flex-col gap-2">
    <template v-if="!canEdit">
      <span v-if="range" class="text-sn-dark-grey">
        <template v-if="colVal.start_time && colVal.end_time">
          {{ colVal.start_time.formatted }} - {{ colVal.end_time.formatted }}
        </template>
        <template v-else>
          {{ viewPlaceholder }}
        </template>
      </span>
      <span v-else class="text-sn-dark-grey">
        <template v-if="colVal.formatted">
          {{ colVal.formatted }}
        </template>
        <template v-else>
          {{ viewPlaceholder }}
        </template>
      </span>
    </template>
    <template v-else>
      <div>
        <span class="text-xs capitalize" v-if="range">{{  i18n.t('general.from') }}</span>
        <DateTimePicker :defaultValue="defaultStartDate" @closed="update" @change="updateStartDate" :mode="mode" :placeholder="placeholder" :clearable="true"/>
      </div>
      <div>
        <span class="text-xs capitalize" v-if="range">{{  i18n.t('general.to') }}</span>
        <DateTimePicker :defaultValue="defaultEndDate" @closed="update" v-if="range" @change="updateEndDate" :placeholder="placeholder" :mode="mode" :clearable="true"/>
      </div>
      <div class="text-xs text-sn-delete-red" v-if="error">{{ error }}</div>
    </template>
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
    };
  },
  inject: ['reloadRepoItemSidebar'],
  props: {
    mode: String,
    range: { type: Boolean, default: false },
    colVal: { type: Object, default: {} },
    colId: Number,
    updatePath: String,
    canEdit: { type: Boolean, default: false },
    colName: String
  },
  created() {
    if (this.range) {
      if (this.colVal.start_time?.datetime) this.startDate = new Date(this.colVal.start_time.datetime);
      if (this.colVal.end_time?.datetime) this.endDate = new Date(this.colVal.end_time.datetime);
    } else if (this.colVal.datetime) this.startDate = new Date(this.colVal.datetime);

    this.defaultStartDate = this.startDate;
    this.defaultEndDate = this.endDate;
  },
  computed: {
    value: {
      get() {
        if (this.range) {
          if (!(this.startDate instanceof Date) && !(this.endDate instanceof Date)) return null;

          return {
            start_time: this.formatDate(this.startDate),
            end_time: this.formatDate(this.endDate)
          };
        }
        if (!(this.startDate instanceof Date)) return null;

        return this.formatDate(this.startDate);
      }
    },
    placeholder() {
      switch (this.mode) {
        case 'date':
          return this.i18n.t('repositories.item_card.repository_date_value.placeholder');
        case 'time':
          return this.i18n.t('repositories.item_card.repository_time_value.placeholder');
        case 'datetime':
          return this.i18n.t('repositories.item_card.repository_date_time_value.placeholder');
        default:
          return '';
      }
    },
    viewPlaceholder() {
      switch (this.mode) {
        case 'date':
          if (this.range) {
            return this.i18n.t('repositories.item_card.repository_date_range_value.no_date_range');
          }
          return this.i18n.t('repositories.item_card.repository_date_value.no_date');
        case 'time':
          if (this.range) {
            return this.i18n.t('repositories.item_card.repository_time_range_value.no_time_range');
          }
          return this.i18n.t('repositories.item_card.repository_time_value.no_time');
        case 'datetime':
          if (this.range) {
            return this.i18n.t('repositories.item_card.repository_date_time_range_value.no_date_time_range');
          }
          return this.i18n.t('repositories.item_card.repository_date_time_value.no_date_time');
        default:
          return '';
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
    trimSecondsAndMilliseconds(date) {
      if (!date) return null;
      if (!(date instanceof Date)) return null;

      if (this.mode === 'time') {
        return new Date().setHours(date.getHours(), date.getMinutes(), 0, 0);
      }

      return date.setSeconds(0, 0);
    },
    validateValue() {
      this.error = null;
      const oldStart = this.trimSecondsAndMilliseconds(this.defaultStartDate);
      const oldEnd = this.trimSecondsAndMilliseconds(this.defaultEndDate);
      const newStart = this.trimSecondsAndMilliseconds(this.startDate);
      const newEnd = this.trimSecondsAndMilliseconds(this.endDate);
      // Date is not changed
      if (oldEnd) {
        if (oldStart === newStart && oldEnd === newEnd) return false;
      } else if (oldStart === newStart) return false;

      if (this.range) {
        // Both empty
        if (!(this.startDate instanceof Date) && !(this.endDate instanceof Date)) return true;

        // One empty
        if (!(this.startDate instanceof Date) || !(this.endDate instanceof Date)) {
          this.error = this.i18n.t('repositories.item_card.date_time.errors.not_valid_range');
          return false;
        }

        // Start date is after end date
        if (this.startDate > this.endDate) {
          this.error = this.i18n.t('repositories.item_card.date_time.errors.not_valid_range');
          return false;
        }
      }

      return true;
    },
    update() {
      const params = {};

      if (!this.validateValue()) return;

      params[this.colId] = this.value;
      $.ajax({
        method: 'PUT',
        url: this.updatePath,
        dataType: 'json',
        data: { repository_cells: params },
        success: () => {
          this.defaultStartDate = this.startDate;
          this.defaultEndDate = this.endDate;
          if ($('.dataTable.repository-dataTable')[0]) {
            $('.dataTable.repository-dataTable').DataTable().ajax.reload(null, false);
          }
          this.reloadRepoItemSidebar();
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
    }
  }
};
</script>
