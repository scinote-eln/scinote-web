<template>
  <div @click="toggle" ref="container" class="sn-select" :class="{ 'sn-select--open': isOpen, 'sn-select--blank': !valueLabel, 'disabled': disabled }">
    <slot>
      <button ref="focusElement" class="sn-select__value">
        <span>{{ valueLabel || (placeholder || i18n.t('general.select')) }}</span>
      </button>
      <span class="sn-select__caret caret"></span>
    </slot>
    <div ref="optionsContainer" class="sn-select__options" :style="optionPositionStyle">
      <div v-for="option in options" :key="option[0]" @click="setValue(option[0])" class="sn-select__option">
        {{ option[1] }}
      </div>
    </div>
  </div>
</template>

<script>
  export default {
    name: 'Select',
    props: {
      options: { type: Array, default: () => [] },
      initialValue: { type: [String, Number] },
      placeholder: { type: String },
      disabled: { type: Boolean, default: false }
    },
    data() {
      return {
        value: null,
        isOpen: false,
        optionPositionStyle: ''
      }
    },
    computed: {
      valueLabel() {
        let option = this.options.find((o) => o[0] === this.value);
        return option && option[1];
      },
      focusElement() {
        return this.$refs.focusElement || this.$scopedSlots.default()[0].context.$refs.focusElement;
      }
    },
    mounted() {
      this.focusElement.onblur = this.blur;
      document.addEventListener("scroll", this.updateOptionPosition);
    },
    methods: {
      blur() {
        setTimeout(() => {
          this.isOpen = false;
          this.$emit('blur');
        }, 200)
      },
      toggle() {
        this.isOpen = !this.isOpen;

        if (this.isOpen) {
          this.$emit('open');
          this.$nextTick(() => {
            this.focusElement.focus();
          });
          this.$refs.optionsContainer.scrollTop = 0;
          this.updateOptionPosition();
        } else {
          this.optionPositionStyle = '';
          this.$emit('close');
        }
      },
      setValue(value) {
        this.value = value;
        this.toggle
        this.$emit('change', this.value);
      },
      updateOptionPosition() {
        const rect = this.$refs.container.getBoundingClientRect();
        const top = rect.height;
        const width = rect.width;

        this.optionPositionStyle = `position: absolute; top: ${top}px; width: ${width}px`
      }
    }
  }
</script>
