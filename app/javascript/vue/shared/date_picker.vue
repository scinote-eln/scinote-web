<template>
  <div class="datepicker">
      <input @change="update" type="datetime" class="form-control calendar-input" :id="this.selectorId" placeholder="" />
  </div>
</template>

<script>
  export default {
    name: 'DatePicker',
    props: {
      selectorId: { type: String, required: true },
      useCurrent: { type: Boolean, default: true }
    },
    mounted() {
      $("#" + this.selectorId).datetimepicker(
        {
          useCurrent: this.useCurrent,
          ignoreReadonly: this.ignoreReadOnly,
          locale: this.i18n.locale,
          format: this.dateFormat
        }
      );

      $("#" + this.selectorId).on('dp.change', (e) => this.update(e.date))
    },
    methods: {
      update(value) {
        this.$emit('change', value.toDate());
      }
    }
  }
</script>
