<template>
  <div class="sci-input-container time-container right-icon">
    <input class="time-part sci-input-field"
           @input="update"
           :id="this.selectorId"
           type="text"
           data-mask-type="time"
           v-model="value"
           placeholder="HH:mm"/>
    <i class="sn-icon sn-icon-created"></i>
  </div>
</template>

<script>
  export default {
    name: 'TimePicker',
    props: {
      selectorId: { type: String, required: true },
      defaultValue: { type: String, required: false }
    },
    data() {
      return {
        value: ''
      }
    },
    mounted() {
      Inputmask('datetime', {
        inputFormat: 'HH:MM',
        placeholder: 'HH:mm',
        clearIncomplete: true,
        showMaskOnHover: true,
        hourFormat: 24
      }).mask($('#' + this.selectorId));

      $('#' + this.selectorId).next().click(() => {
        var inputField = $('#' + this.selectorId);
        var d = new Date();
        var h = ('0' + d.getHours()).slice(-2);
        var m = ('0' + d.getMinutes()).slice(-2);
        var value= h + ':' + m
        inputField.val(value);
        this.value = value;
        this.update();
      });

      this.value = this.defaultValue;
      this.update();
    },
    methods: {
      update() {
        this.$emit('change', this.value);
      }
    }
  }
</script>
