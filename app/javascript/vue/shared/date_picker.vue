<template>
  <div class="datepicker sci-input-container right-icon">
      <input
        @change="update"
        type="datetime"
        class="form-control calendar-input sci-input-field"
        :id="this.selectorId"
        placeholder='dd/mm/yyyy'
      />
      <i class="sn-icon sn-icon-calendar"></i>
  </div>
</template>

<script>
  export default {
    name: 'DatePicker',
    props: {
      selectorId: { type: String, required: true },
      useCurrent: { type: Boolean, default: true },
      defaultValue: { type: Date, default: null }
    },
    mounted() {
      $("#" + this.selectorId).datetimepicker(
        {
          useCurrent: this.useCurrent,
          ignoreReadonly: this.ignoreReadOnly,
          locale: this.i18n.locale,
          format: this.dateFormat,
          date: this.defaultValue
        }
        );
      $("#" + this.selectorId).on('dp.change', (e) => this.update(e.date))
    },
    methods: {
      update(value) {
        this.$emit('change', (value._isAMomentObject) ? value.toDate() : '');
      },
      isValidDate(date) {
        return (date instanceof Date) && !isNaN(date.getTime());
      },
    }
  }
</script>
