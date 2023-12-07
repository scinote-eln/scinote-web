<template>
  <div v-click-outside="close" @click="toggle" ref="container" class="sn-select" :class="{ 'sn-select--open': isOpen, 'sn-select--blank': !valueLabel, 'disabled': disabled }">
    <slot>
      <button ref="focusElement" class="sn-select__value">
        <span>{{ valueLabel || (placeholder || i18n.t('general.select')) }}</span>
      </button>
      <i class="sn-icon" :class="{ 'sn-icon-down': !isOpen, 'sn-icon-up': isOpen}"></i>
    </slot>
    <div :style="optionPositionStyle" class="py-2.5 bg-white z-10 shadow-sn-menu-sm" :class="{ 'hidden': !isOpen }">
      <div v-if="withClearButton" class="px-2 pb-2.5">
        <div @mousedown.prevent.stop="setValue(null)"
             class="btn btn-light !text-xs active:bg-sn-super-light-blue"
             :class="{
               'disabled cursor-default': !value,
               'cursor-pointer': value,
             }">
          {{ i18n.t('general.clear') }}
        </div>
      </div>
      <perfect-scrollbar ref="optionsContainer"
                         class="sn-select__options !relative !top-0 !left-[-1px] !shadow-none scroll-container px-2.5 pt-0 block"
                         :class="{ [optionsClassName]: true }"
      >
        <div v-if="options.length" class="flex flex-col gap-[1px]">
          <div
            v-for="option in options"
            :key="option[0]"
            @mousedown.prevent.stop="setValue(option[0])"
            class="sn-select__option p-3 rounded shadow-none"
            :title="option[1]"
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
  </div>
</template>
<script>
  import { vOnClickOutside } from '@vueuse/components'

  export default {
    name: 'Select',
    props: {
      withClearButton: { type: Boolean, default: false },
      withEditCursor: { type: Boolean, default: false },
      value: { type: [String, Number] },
      options: { type: Array, default: () => [] },
      initialValue: { type: [String, Number] },
      placeholder: { type: String },
      noOptionsPlaceholder: { type: String },
      className: { type: String, default: '' },
      optionsClassName: { type: String, default: '' },
      disabled: { type: Boolean, default: false }
    },
    directives: {
      'click-outside': vOnClickOutside
    },
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
      }
    },
    mounted() {
      document.addEventListener('scroll', this.updateOptionPosition);
    },
    beforeUnmount() {
      document.removeEventListener('scroll', this.updateOptionPosition);
    },
    methods: {
      toggle() {
        this.isOpen = !this.isOpen;

        if (this.isOpen) {
          this.$emit('open');
          this.$nextTick(() => {
            this.$emit('focus');
            this.$refs.focusElement?.focus();
          });
          this.$refs.optionsContainer.scrollTop = 0;
          this.updateOptionPosition();
        } else {
          this.close()
        }
      },
      close() {
        this.isOpen = false;
        this.optionPositionStyle = '';
        this.$emit('close');
      },
      setValue(value) {
        this.$emit('change', value);
      },
      updateOptionPosition() {
        const container = $(this.$refs.container);
        const rect = container.get(0).getBoundingClientRect();
        const screenHeight = window.innerHeight;
        let width = rect.width;
        let height = rect.height;
        let top = rect.top + rect.height;
        let bottom = screenHeight - rect.bottom + rect.height;
        let left = rect.left;

        const modal = container.parents('.modal-content');

        if (modal.length > 0) {
          const modalRect = modal.get(0).getBoundingClientRect();
          top -= modalRect.top;
          bottom -= modalRect.bottom;
          left -= modalRect.left;
          this.optionPositionStyle = `position: fixed; top: ${top}px; left: ${left}px; width: ${width}px`
        } else {
          container.addClass('relative');
          this.optionPositionStyle = `position: absolute; top: ${height}px; left: 0px; width: ${width}px`
        }
      }
    }
  }
</script>
