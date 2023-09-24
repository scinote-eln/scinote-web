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
      class="sn-select__options scroll-container p-2.5 block"
    >
      <div v-if="options.length" class="flex flex-col gap-[1px]">
        <div
          v-for="option in options"
          :key="option[0]"
          @mousedown.prevent.stop="setValue(option[0])"
          class="sn-select__option p-3 rounded"
          :class="{
            'select__option-placeholder': option[2],
            '!bg-sn-super-light-blue': option[0] == value,
          }"
        >
          {{ option[1] }}
        </div>
      </div>
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
        optionPositionStyle: '',
        blurPrevented: false
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
      document.addEventListener('scroll', this.updateOptionPosition);
    },
    beforeDestroy() {
      document.removeEventListener('scroll', this.updateOptionPosition);
    },
    methods: {
      preventBlur() {
        this.blurPrevented = true;
      },
      allowBlur() {
        setTimeout(() => { this.blurPrevented = false }, 200);
      },
      blur() {
        setTimeout(() => {
          if (this.blurPrevented) {
            this.focusElement.focus();
          } else {
            this.isOpen = false;
            this.$emit('blur');
          }
        }, 100);
      },
      toggle() {
        if (this.isOpen && this.blurPrevented) {
          return;
        }

        this.isOpen = !this.isOpen;

        if (this.isOpen) {
          this.$emit('open');
          this.$nextTick(() => {
            this.focusElement.focus();
          });
          this.$refs.optionsContainer.scrollTop = 0;
          this.updateOptionPosition();
          this.setUpBlurHandlers();
        } else {
          this.optionPositionStyle = '';
          this.$emit('close');
        }
      },
      setValue(value) {
        this.focusElement.blur();
        this.$emit('change', value);
      },
      updateOptionPosition() {
        const container = $(this.$refs.container);
        const rect = container.get(0).getBoundingClientRect();
        const screenHeight = window.innerHeight;
        let width = rect.width;
        let top = rect.top + rect.height;
        let bottom = screenHeight - rect.bottom + rect.height;
        let left = rect.left;

        const modal = container.parents('.modal-content');

        if (modal.length > 0) {
          const modalRect = modal.get(0).getBoundingClientRect();
          top -= modalRect.top;
          bottom -= modalRect.bottom;
          left -= modalRect.left;
        }

        if (rect.bottom > screenHeight / 2) {
          this.optionPositionStyle = `
            position: fixed;
            bottom: ${bottom}px;
            left: ${left}px;
            width: ${width}px`
        } else {
          this.optionPositionStyle = `
            position: fixed;
            top: ${top}px;
            left: ${left}px;
            width: ${width}px`
        }
      },
      setUpBlurHandlers() {
        setTimeout(() => {
          this.$refs.optionsContainer.$el.querySelector('.ps__thumb-y').addEventListener('mousedown', this.preventBlur);
          this.$refs.optionsContainer.$el.querySelector('.ps__thumb-y').addEventListener('mouseup', this.allowBlur);
          document.addEventListener('mouseup', this.allowBlur);
        }, 100);
      }
    }
  }
</script>
