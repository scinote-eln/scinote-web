<template>
  <div @click="toggle" ref="container" class="sn-select" :class="{ 'sn-select--open': isOpen, 'sn-select--blank': !valueLabel, 'disabled': disabled }">
    <slot>
      <button ref="focusElement" class="sn-select__value">
        <span>{{ valueLabel || (placeholder || i18n.t('general.select')) }}</span>
      </button>
      <i class="sn-icon" :class="{ 'sn-icon-down': !isOpen, 'sn-icon-up': isOpen}"></i>
    </slot>
    <perfect-scrollbar
      ref="optionsContainer"
      :style="optionPositionStyle"
      class="sn-select__options scroll-container"
    >
      <template v-if="options.length">
        <div
          v-for="option in options"
          :key="option[0]" @click="setValue(option[0])"
          class="sn-select__option"
        >
          {{ option[1] }}
        </div>
      </template>
      <template v-else>
        <div
          class="sn-select__no-options"
        >
          {{ this.noOptionsPlaceholder }}
        </div>
      </template>
    </perfect-scrollbar>
  </div>
</template>
<script>
  import PerfectScrollbar from 'vue2-perfect-scrollbar';

  export default {
    name: 'Select',
    props: {
      value: { type: [String, Number] },
      options: { type: Array, default: () => [] },
      initialValue: { type: [String, Number] },
      placeholder: { type: String },
      noOptionsPlaceholder: { type: String },
      disabled: { type: Boolean, default: false }
    },
    comments: { PerfectScrollbar },
    data() {
      return {
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
        }, 200);
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
        this.$emit('change', value);
      },
      updateOptionPosition() {
        const container = $(this.$refs.container);
        const rect = container.get(0).getBoundingClientRect();
        let width = rect.width;
        let top = rect.top + rect.height;
        let left = rect.left;

        const modal = container.parents('.modal-content');

        if (modal.length > 0) {
          const modalRect = modal.get(0).getBoundingClientRect();
          top -= modalRect.top;
          left -= modalRect.left;
        }

        this.optionPositionStyle = `position: fixed; top: ${top}px; left: ${left}px; width: ${width}px`
      }
    }
  }
</script>
