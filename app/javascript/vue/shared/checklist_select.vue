<template>
  <div class="w-full relative" ref="container" v-click-outside="closeDropdown">
    <slot>
      <button ref="focusElement"
              class="btn flex justify-between items-center w-full outline-none border-[1px] bg-white rounded sn-select
              font-inter text-sm font-normal leading-5"
              :class="{
                'sci-cursor-edit': !isOpen && withEditCursor,
                'border-sn-light-grey hover:border-sn-sleepy-grey': !isOpen,
                'sn-select--open': isOpen,
                'text-sn-grey': !valueLabel,
                [className]: true
              }"
              :disabled="disabled"
              @click="isOpen = !isOpen">
        <span class="overflow-hidden text-ellipsis">{{ valueLabel || this.placeholder || this.i18n.t('general.select') }}</span>
        <i class="sn-icon" :class="{ 'sn-icon-down': !isOpen, 'sn-icon-up': isOpen}"></i>
      </button>
    </slot>
    <div :style="optionPositionStyle" class="py-2.5 z-10 bg-white rounded border-[1px] border-sn-light-grey shadow-sn-menu-sm" :class="{ 'hidden': !isOpen }">
      <div v-if="withButtons" class="px-2.5 pb-[1px]">
        <div class="flex gap-2 pl-[0.625rem] justify-start items-center w-[calc(100%-10px)]">
          <div class="btn btn-light !text-xs h-[30px] px-0 active:bg-sn-super-light-blue"
               @click="selectedValues = []"
               :class="{
                 'disabled cursor-default': !selectedValues.length,
                 'cursor-pointer': selectedValues.length
               }"
              >{{ i18n.t('general.clear') }}</div>
          <div class="btn btn-light !text-xs h-[30px] px-0 active:bg-sn-super-light-blue"
               @click="selectedValues = options.map(option => option.id)"
               :class="{
                'disabled cursor-default': options.length === selectedValues.length,
                'cursor-pointer': options.length !== selectedValues.length}">
               {{ i18n.t('general.select_all') }}
          </div>
        </div>
      </div>
      <perfect-scrollbar ref="optionsContainer"
                         class="relative scroll-container px-2.5 pt-0"
                         :class="{
                           'block': isOpen,
                           [optionsClassName]: true
                         }"
                         @ps-scroll-y="onScroll">
        <div v-if="options.length" class="flex flex-col gap-[1px]">
          <div v-for="option in options"
               :key="option.id"
               class="checklist px-3 py-2 rounded hover:bg-sn-super-light-grey cursor-pointer
                flex gap-1 justify-start items-center"
               :class="option.id === this.lastSelectedOption ? 'bg-sn-super-light-blue hover:bg-sn-super-light-blue' : ''"
               @change="toggleOption"
               @click="triggerLabelClick($event, option.id)"
               >
            <div class="sci-checkbox-container">
              <input v-model="selectedValues" :value="option.id" :id="option.id" type="checkbox" class="sci-checkbox project-card-selector">
              <label :for="option.id" class="sci-checkbox-label"></label>
            </div>
            <span :title="option.label"
              class="text-ellipsis overflow-hidden max-h-[4rem] ml-1 whitespace-normal line-clamp-3 option-label"
            >
              {{ option.label }}
            </span>
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
import { vOnClickOutside } from '@vueuse/components';

export default {
  name: 'ChecklistSelect',
  emits: ['close', 'update', 'reached-end', 'update-selected-values'],
  props: {
    withButtons: { type: Boolean, default: false },
    withEditCursor: { type: Boolean, default: false },
    initialSelectedValues: { type: Array, default: () => [] },
    options: { type: Array, default: () => [] },
    placeholder: { type: String },
    noOptionsPlaceholder: { type: String },
    disabled: { type: Boolean, default: false },
    className: { type: String, default: '' },
    shouldOpen: { type: Boolean },
    optionsClassName: { type: String, default: '' },
    shouldUpdateWithoutValues: { type: Boolean, default: false },
    shouldUpdateOnToggleClose: { type: Boolean, default: false }
  },
  directives: {
    'click-outside': vOnClickOutside
  },
  data() {
    return {
      selectedValues: [],
      isOpen: false,
      optionPositionStyle: '',
      lastSelectedOption: null
    };
  },
  mounted() {
    this.selectedValues = this.initialSelectedValues;
  },
  computed: {
    valueLabel() {
      if (!this.selectedValues.length) return;
      if (this.selectedValues.length === 1) return this.options.find(({ id }) => id === this.selectedValues[0])?.label;
      return `${this.selectedValues.length} ${this.i18n.t('general.selected')}`;
    },
    focusElement() {
      return this.$refs.focusElement || this.$parent.$refs.focusElement;
    }
  },
  watch: {
    initialSelectedValues: {
      handler(newVal, oldVal) {
        this.selectedValues = newVal;
      },
      deep: true
    },
    shouldOpen(value) {
      this.isOpen = value;
    },
    isOpen(value) {
      if (value) {
        this.updateOptionPosition();
        this.$refs.optionsContainer.scrollTop = 0;
        this.$nextTick(() => {
          this.focusElement.focus();
        });
      } else {
        if (this.shouldUpdateOnToggleClose && this.shouldUpdateWithoutValues) {
          this.$emit('update', this.selectedValues);
        }
        this.closeDropdown();
      }
      this.lastSelectedOption = null;
    },
    selectedValues(values) {
      this.$emit('update-selected-values', values);
    }
  },
  methods: {
    updateOptionPosition() {
      const container = $(this.$refs.container);
      const rect = container.get(0).getBoundingClientRect();
      const { width } = rect;
      const { height } = rect;
      this.optionPositionStyle = `position: absolute; top: ${height}px; left: 0px; width: ${width}px`;
    },
    toggleOption(option) {
      const optionId = option.target._value;
      this.setLastSelected(optionId);
    },
    setLastSelected(optionId) {
      this.lastSelectedOption = this.selectedValues.includes(optionId) ? optionId : null;
    },
    closeDropdown() {
      if (!this.isOpen) return;

      this.isOpen = false;
      if (this.shouldUpdateWithoutValues) {
        this.$emit('update', this.selectedValues);
      }
      if (this.selectedValues.length && !this.shouldUpdateWithoutValues) {
        this.$emit('update', this.selectedValues);
      }
      this.$emit('close');
      this.$refs.optionsContainer.$el.scrollTop = 0;
    },
    triggerLabelClick(event, optionId) {
      if ($(event.target).hasClass('sci-checkbox')) return;
      if ($(event.target).hasClass('sci-checkbox-label')) return;

      $(event.target).closest('.checklist').find(`#${optionId}`).trigger('click');
    },
    onScroll() {
      const scrollObj = this.$refs.optionsContainer.ps;

      if (scrollObj) {
        const reachedEnd = scrollObj.reach.y === 'end';
        if (reachedEnd && this.contentHeight !== scrollObj.contentHeight) {
          this.$emit('reached-end');
          this.contentHeight = scrollObj.contentHeight;
        }
      }
    }
  }
};
</script>
