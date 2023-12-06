export default {
  data() {
    return {
      isSaving: null,
    };
  },
  computed: {
    borderColor() {
      if (this.errorMessage) return 'border-sn-delete-red';
      if (this.isEditing) return 'border-sn-science-blue';
      return 'border-sn-light-grey hover:border-sn-sleepy-grey';
    },
    isEditable() {
      return this.isEditing && this.editingField === this.dateType
    }
  },
  methods: {
    enableEdit() {
      this.isEditing = true
      this.$emit('setEditingField', this.dateType)
    },
    saveChange() {
      if (!this.isEditing ||
          this.isSaving ||
          !this.params ||
          (this.params && !Object.keys(this.params).includes(this.colId?.toString()))) {
        Object.assign(this.$data, { isEditing: false, isSaving: false, errorMessage: null });
        return;
      };

      // Don't submit unless values changed
      switch (true) {
        case ['date', 'dateTime', 'time'].includes(this.dateType):
          if(this.equalDates(this.params[this.colId], this.initDate)) {
            Object.assign(this.$data, { isEditing: false, isSaving: false });
            return;
          }
          if(this.dateType === 'time' && this.equalTimes(this.params[this.colId], this.initDate)) {
            Object.assign(this.$data, { isEditing: false, isSaving: false });
            return;
          }
        case ['dateRange', 'dateTimeRange', 'timeRange'].includes(this.dateType):
          if (this.equalDates(this.timeFrom?.datetime, this.initStartDate) &&
              this.equalDates(this.timeTo?.datetime, this.initEndDate)) {
            Object.assign(this.$data, { isEditing: false, isSaving: false });
            return;
          }
          if (this.dateType === 'timeRange' &&
              this.equalTimes(this.timeFrom?.datetime, this.initStartDate) &&
              this.equalTimes(this.timeTo?.datetime, this.initEndDate)) {
            Object.assign(this.$data, { isEditing: false, isSaving: false });
            return;
          }
        default:
          break;
      }
      Object.assign(this.$data, { isSaving: true, errorMessage: null });
      const $this = this;
      $.ajax({
        method: 'PUT',
        url: $this.cellUpdatePath,
        dataType: 'json',
        data: { repository_cells: $this.params },
        success: (result) => {
          const cellValue = result?.value;
          switch (true) {
            case ['date', 'dateTime', 'time'].includes(this.dateType):
              this.values = cellValue
              this.initDate = cellValue?.datetime
            case ['dateRange', 'dateTimeRange', 'timeRange'].includes(this.dateType):
              this.initStartDate = cellValue?.start_time?.datetime;
              this.initEndDate = cellValue?.end_time?.datetime;
            default:
              break;
          }
          Object.assign($this.$data, { isEditing: false, isSaving: false, values: result?.value });
          if ($('.dataTable')[0]) $('.dataTable').DataTable().ajax.reload(null, false);
        }
      });
    },
    setParams() {
      let defaultParams = this.params ? this.params : { [this.colId]: {} };
      switch (true) {
        case ['date', 'dateTime', 'time'].includes(this.dateType):
          defaultParams[this.colId] = this.values?.datetime;
          break;
        case ['dateRange', 'dateTimeRange', 'timeRange'].includes(this.dateType):
          defaultParams[this.colId]['start_time'] = this.timeFrom?.datetime;
          defaultParams[this.colId]['end_time'] = this.timeTo?.datetime;
          break;
        default:
          break;
      }
      this.params = defaultParams;
    },
    formatDateTime(date, field = null) {
      this.values = this.values ? this.values : { [this.colId]: {} }
      let params = this.params && this.params[this.colId] ? this.params : { [this.colId]: {} };
      let timeFrom = this.timeFrom || {};
      let timeTo = this.timeTo || {};
      switch (true) {
        case ['date', 'dateTime', 'time'].includes(this.dateType):
          params[this.colId] = date;
          this.values['datetime'] = date;
          break;
        case ['dateRange', 'dateTimeRange', 'timeRange'].includes(this.dateType):
          if (field === 'start_time') {
            timeFrom['datetime'] = date;
          }
          if (field === 'end_time'){
            timeTo['datetime'] = date;
          }
          params[this.colId][field] = date;
          break;
        default:
          break;
      }
      this.timeFrom = timeFrom;
      this.timeTo = timeTo;
      this.params = params;
    },
    dateValue(date) {
      if(date) return new Date(date)
      return new Date()
    },
    hasMonthText(){
      $('body').data('datetime-picker-format')?.match(/MMM/)
    },
    equalDates(date1, date2){
      return new Date(date1).getTime() === new Date(date2).getTime();
    },
    equalTimes(date1, date2){
      return new Date(date1).getHours() === new Date(date2).getHours() &&
              new Date(date1).getMinutes() == new Date(date2).getMinutes()
    },
    validateAndSave() {
      this.errorMessage = null;
      switch (true) {
        case ['date', 'dateTime', 'time'].includes(this.dateType):
          // To do
          break;
        case ['dateRange', 'dateTimeRange', 'timeRange'].includes(this.dateType):
          if(this.params && this.params[this.colId]) {
            if((!this.params[this.colId].start_time && this.params[this.colId].end_time) ||
              (this.params[this.colId].start_time && !this.params[this.colId].end_time)) {
              this.errorMessage = I18n.t('repositories.item_card.date_time.errors.not_valid_range');
              return;
            }
            if (this.params[this.colId].start_time && this.params[this.colId].end_time &&
                this.params[this.colId].start_time.getTime() && this.params[this.colId].end_time.getTime()) {
              if(this.params[this.colId].start_time.getTime() > this.params[this.colId].end_time.getTime()) {
                this.errorMessage = I18n.t('repositories.item_card.date_time.errors.not_valid_range');
                return
              }
            }
            if (!this.params[this.colId].start_time && !this.params[this.colId].end_time) {
              this.params = { [this.colId]: null }
            }
          }
          break;
        default:
          break;
      }
      this.saveChange();
    }
  },
};
