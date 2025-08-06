<template>
  <div class="w-full h-8 relative">
    <input
      ref="input"
      type="text"
      :placeholder="placeholder"
      :value="modelValue"
      @input="emitValue"
      class="outline-none text-2xl font-bold shadow-none placeholder:text-sn-grey h-full border !border-transparent w-full px-0"
      :class="{
        '!border-b-sn-delete-red !text-base pb-3': error,
        'focus:!border-b-sn-science-blue': !error,
      }"
    />
    <div v-if="error && errorMessage" class="text-sn-delete-red text-xs absolute left-0 bottom-0.5 leading-3">
      {{ errorMessage }}
    </div>
  </div>
</template>

<script>
export default {
  name : 'InputTitleField',
  props: {
    modelValue: {
      type: String,
      default: ''
    },
    placeholder: {
      type: String,
      default: ''
    },
    error: {
      type: Boolean,
      default: null
    },
    errorMessage: {
      type: String,
      default: null
    }
  },
  methods: {
    emitValue(e) {
      this.$emit('update:modelValue', e.target.value);
    }
  }
};
</script>
