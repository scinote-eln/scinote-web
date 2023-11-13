<template>
  <div v-if="!standAlone" class="sci-input-container time-container right-icon">
    <input class="time-part sci-input-field"
      @input="update"
      :id="this.selectorId"
      type="text"
      data-mask-type="time"
      v-model="value"
      placeholder="HH:mm"/>
    <i class="sn-icon sn-icon-created"></i>
  </div>
  <span v-else :class="className">
    <input class="time-part sci-input-field w-full inline-block m-0 p-0 border-none shadow-none outline-none"
      @input="update"
      :id="this.selectorId"
      type="text"
      data-mask-type="time"
      :disabled="disabled"
      v-model="value"
      placeholder="HH:mm"
    />
  </span>
</template>

<script>
  export default {
    name: 'TimePicker',
    props: {
      selectorId: { type: String, required: true },
      defaultValue: { type: String, required: false },
      standAlone: { type: Boolean, default: true, required: false },
      className: { type: String, default: '', required: false },
      disabled: { type: Boolean, default: false }
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
