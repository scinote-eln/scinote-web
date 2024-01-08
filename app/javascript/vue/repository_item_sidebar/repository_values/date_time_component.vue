<template>
  <div ref="dateTimeRangeOverlay"
         class="fixed top-0 left-0 right-0 bottom-0 bg-transparent z-[99] hidden">
    </div>
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
        <DateTimePicker :defaultValue="defaultStartDate" @closed="update" @change="updateStartDate" :mode="mode" :placeholder="placeholder" :clearable="true" ref="dateTimePickerFrom"/>
      </div>
      <div>
        <span class="text-xs capitalize" v-if="range">{{  i18n.t('general.to') }}</span>
        <DateTimePicker :defaultValue="defaultEndDate" @closed="update" v-if="range" @change="updateEndDate" :placeholder="placeholder" :mode="mode" :clearable="true" ref="dateTimePickerTo"/>
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
        defaultEndDate: null,
        fromPicker: null,
        toPicker: null
      }
    },
    inject: ['reloadRepoItemSidebar'],
    props: {
      mode: String,
      range: { type: Boolean, default: false },
      colVal: { type: Object, default: {} },
      colId: Number,
      updatePath: String,
      canEdit: { type: Boolean, default: false },
      colName: String,
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
    mounted() {
      this.fromPicker = this.$refs.dateTimePickerFrom;
      this.toPicker = this.$refs.dateTimePickerTo;
      document.addEventListener('click', this.logClick);
      document.addEventListener('keydown', this.handleKeyDown);
    },
    beforeUnmount() {
      this.fromPicker = null;
      this.toPicker = null;
      document.removeEventListener('click', this.logClick);
      document.removeEventListener('keydown', this.handleKeyDown);
    },
    computed: {
      value: {
        get() {
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
            if ($('.dataTable')[0]) {
              $('.dataTable').DataTable().ajax.reload(null, false);
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
      },
      showOverlay() {
        const overlay = this.$refs.dateTimeRangeOverlay;
        overlay.classList.remove('hidden');
      },
      hideOverlay() {
        const overlay = this.$refs.dateTimeRangeOverlay;
        overlay.classList.add('hidden');
      },
      preventBodyScrolling() {
        document.body.classList.add('overflow-hidden');
        document.body.classList.remove('overflow-auto');
      },
      allowBodyScrolling() {
        document.body.classList.remove('overflow-hidden');
        document.body.classList.add('overflow-auto');
      },
      bringCalendarToFront() {
        const calendarEl = document.querySelector('.dp__instance_calendar');
        calendarEl.classList.add('z-[9999]');
      },
      focusClearedInput() {
        if (!this.fromPicker.datetime) {
          const fromInput = this.fromPicker.$el.querySelector('input');
          fromInput.focus();
          fromInput.click();
        }
        if (!this.toPicker.datetime) {
          const toInput = this.toPicker.$el.querySelector('input');
          toInput.focus();
          toInput.click();
        }

        this.preventBodyScrolling();
        this.showOverlay();
        this.$nextTick(() => {
          this.bringCalendarToFront();
        });
      },
      logClick() {
        if (this.error) this.focusClearedInput();
      },
      handleKeyDown(event) {
        if (event.key === 'Escape' || (event.ctrlKey && event.key === 'z')) {
          if (this.startDate === null && this.fromPicker) {
            this.startDate = this.defaultStartDate;
            this.fromPicker.datetime = this.defaultStartDate;
            this.error = null;
          }
          if (this.endDate === null && this.toPicker) {
            this.endDate = this.defaultEndDate;
            this.toPicker.datetime = this.defaultEndDate;
            this.error = null;
          }
        }
      },
    },
    watch: {
      error(newVal) {
        if (newVal !== null) {
          this.focusClearedInput();
        } else {
          this.hideOverlay();
          this.allowBodyScrolling();
        }
      }
    },
  }
</script>
