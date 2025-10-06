<template>
  <div>
    <label
      v-if="label"
      @click="$refs.input.click()"
      class="text-sm font-bold mb-0 flex items-center gap-1"
    >
      {{ label }}
      <span v-if="required" class="text-sn-alert-passion">*</span>
      <div v-if="helpDescription" class="font-normal">
        <GeneralDropdown>
          <template v-slot:field>
            <i class="sn-icon sn-icon-info cursor-pointer text-sn-grey"></i>
          </template>
          <template v-slot:flyout>
            <div class="p-2" v-html="helpDescription"></div>
          </template>
        </GeneralDropdown>
      </div>
    </label>
    <div v-if="subLabel">{{ subLabel }}</div>
    <div class="relative h-11 my-2">
      <div v-if="leftIcon" class="absolute left-2 top-1/2 transform -translate-y-1/2">
        <i :class="leftIcon" class="sn-icon"></i>
      </div>
      <input
        ref="input"
        :type="type"
        :placeholder="placeholder"
        :disabled="disabled"
        :value="modelValue"
        @input="emitValue"
        @blur="$emit('blur')"
        @focus="$emit('focus')"
        class="outline-none shadow-none placeholder:text-sn-grey rounded h-full border border-sn-sleepy-grey bg-white w-full px-4 focus:border-sn-science-blue"
        :class="{
          '!bg-sn-super-light-grey ': disabled,
          '!border-sn-alert-passion': error,
          '!border-sn-alert-brittlebush': warning,
          'pl-9': leftIcon,
          'pr-10': rightIcon
        }"
      />
      <div v-if="rightIcon" class="absolute right-2 top-1/2 transform -translate-y-1/2">
        <i :class="rightIcon" class="sn-icon"></i>
      </div>
    </div>
    <div v-if="error && errorMessage" class="text-xs text-sn-alert-passion">{{ errorMessage }}</div>
    <div v-if="warning && warningMessage" class="text-xs text-sn-alert-brittlebush">{{ warningMessage }}</div>
  </div>
</template>

<script>
import GeneralDropdown from './general_dropdown.vue';

export default {
  name: 'InputField',
  components: {
    GeneralDropdown
  },
  props: {
    modelValue: {
      type: String,
      default: ''
    },
    type: {
      type: String,
      default: 'text'
    },
    required: {
      type: Boolean,
      default: false
    },
    placeholder: {
      type: String,
      default: ''
    },
    disabled: {
      type: Boolean,
      default: false
    },
    label: {
      type: String,
      default: null
    },
    subLabel: {
      type: String,
      default: null
    },
    helpDescription: {
      type: String,
      default: null
    },
    leftIcon: {
      type: String,
      default: null
    },
    rightIcon: {
      type: String,
      default: null
    },
    error: {
      type: Boolean,
      default: null
    },
    errorMessage: {
      type: String,
      default: null
    },
    warning: {
      type: Boolean,
      default: null
    },
    warningMessage: {
      type: String,
      default: null
    },
    isNumber: {
      type: Boolean,
      default: false
    }
  },
  methods: {
    focus() {
      this.$refs.input.focus();
    },
    emitValue(e) {
      let newValue = e.target.value;
      if (this.isNumber) {
        [newValue] = newValue.replace(/[^-0-9.]/g, '').match('^-?\\d*(\\.\\d{0,50})?');
        this.$emit('update:modelValue', e.target.value);
        this.$nextTick(() => {
          this.$emit('update:modelValue', newValue);
        });
      } else {
        this.$emit('update:modelValue', newValue);
      }
    }
  }
};
</script>
