<template>
  <div v-if="!standAlone" class="datepicker sci-input-container right-icon">
    <input
      @change="update"
      type="datetime"
      class="form-control calendar-input sci-input-field"
      :id="this.selectorId"
      :placeholder="placeholder || 'dd/mm/yyyy'"
    />
    <i class="sn-icon sn-icon-calendar"></i>
  </div>
  <div :class="className" v-else>
    <input
      @input="update"
      type="datetime"
      class='inline-block m-0 p-0 w-full border-none shadow-none outline-none'
      :id="this.selectorId"
      :placeholder="placeholder || 'dd/mm/yyyy'"
    />
  </div>
</template>

<script>
  import '../../../../vendor/assets/javascripts/bootstrap-datetimepicker';

  export default {
    name: 'DatePicker',
    props: {
      placeholder: { type: String },
      selectorId: { type: String, required: true },
      useCurrent: { type: Boolean, default: true },
      defaultValue: { type: Date, default: null },
      standAlone: { type: Boolean, default: false, required: false },
      className: { type: String, default: '' }
    },
    mounted() {
      $("#" + this.selectorId).datetimepicker(
        {
          useCurrent: this.useCurrent,
          ignoreReadonly: this.ignoreReadOnly,
          locale: this.i18n.locale,
          format: $('body').data('datetime-picker-format'),
          date: this.defaultValue
        }
        );
      $("#" + this.selectorId).on('dp.change', (e) => this.update(e.date))
      if (this.isValidDate(this.defaultValue)) this.update(moment(this.defaultValue));
    },
    methods: {
      update(value) {
        this.$emit('change', (value?._isAMomentObject) ? value.toDate() : '');
      },
      isValidDate(date) {
        return (date instanceof Date) && !isNaN(date.getTime());
      },
    }
  }
</script>
