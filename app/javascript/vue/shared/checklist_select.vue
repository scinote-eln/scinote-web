<template>
  <div class="w-full relative" ref="container" v-click-outside="closeDropdown">
    <button ref="focusElement"
            class="btn flex justify-between items-center w-full outline-none border-[1px] bg-white rounded p-2
                  font-inter text-sm font-normal leading-5"
            :class="{
              'sci-cursor-edit': !isOpen && withEditCursor,
              'border-sn-light-grey hover:border-sn-sleepy-grey': !isOpen,
              'border-sn-science-blue': isOpen,
              'text-sn-grey': !valueLabel,
              [className]: true
            }"
            :disabled="disabled"
            @click="toggle">
      <span class="overflow-hidden text-ellipsis">{{ valueLabel || this.placeholder || this.i18n.t('general.select') }}</span>
      <i class="sn-icon" :class="{ 'sn-icon-down': !isOpen, 'sn-icon-up': isOpen}"></i>
    </button>
    <div :style="optionPositionStyle" class="py-2.5 z-10 bg-white rounded border-[1px] border-sn-light-grey shadow-sn-menu-sm" :class="{ 'hidden': !isOpen }">
      <div v-if="withButtons" class="px-2.5 pb-[1px]">
        <div class="flex gap-2 pl-2 justify-start items-center w-[calc(100%-10px)]">
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
                         }">
        <div v-if="options.length" class="flex flex-col gap-[1px]">
          <div v-for="option in options"
               :key="option.id"
               class="px-3 py-2 rounded hover:bg-sn-super-light-grey cursor-pointer flex gap-1 justify-start items-center">
            <div class="sci-checkbox-container">
              <input v-model="selectedValues" :value="option.id" :id="option.id" type="checkbox" class="sci-checkbox project-card-selector">
              <label :for="option.id" class="sci-checkbox-label"></label>
            </div>
            <span :title="option.label" class="text-ellipsis overflow-hidden max-h-[4rem] ml-1 whitespace-normal line-clamp-3">{{ option.label }}</span>
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
  import PerfectScrollbar from 'vue3-perfect-scrollbar';
  import { vOnClickOutside } from '@vueuse/components'

  export default {
    name: 'ChecklistSelect',
    comments: { PerfectScrollbar },
    props: {
      withButtons: { type: Boolean, default: false },
      withEditCursor: { type: Boolean, default: false },
      initialSelectedValues: { type: Array, default: () => [] },
      options: { type: Array, default: () => [] },
      placeholder: { type: String },
      noOptionsPlaceholder: { type: String },
      disabled: { type: Boolean, default: false },
      className: { type: String, default: '' },
      optionsClassName: { type: String, default: '' }
    },
    directives: {
      'click-outside': vOnClickOutside
    },
    data() {
      return {
        selectedValues: [],
        isOpen: false,
        optionPositionStyle: ''
      }
    },
    mounted() {
      this.selectedValues = this.initialSelectedValues;
    },
    computed: {
      valueLabel() {
        if (!this.selectedValues.length) return
        if (this.selectedValues.length === 1) return this.options.find(({id}) => id === this.selectedValues[0])?.label
        return `${this.selectedValues.length} ${this.i18n.t('general.selected')}`;
      }
    },
    watch: {
      initialSelectedValues: {
        handler: function (newVal) {
          this.selectedValues = newVal;
        },
        deep: true
      }
    },
    methods: {
      toggle() {
        this.isOpen = !this.isOpen;
        if (this.isOpen) {
          this.updateOptionPosition();
        } else {
          this.closeDropdown();
        }
      },
      updateOptionPosition() {
        const container = $(this.$refs.container);
        const rect = container.get(0).getBoundingClientRect();
        let width = rect.width;
        let height = rect.height;
        this.optionPositionStyle = `position: absolute; top: ${height}px; left: 0px; width: ${width}px`
      },
      toggleOption(id) {
        if (this.selectedValues.includes(id)) {
          this.selectedValues = this.selectedValues.filter((value) => value !== id);
        } else {
          this.selectedValues.push(id);
        }
      },
      closeDropdown() {
        if (!this.isOpen) return;

        this.isOpen = false;
        this.$emit('update', this.selectedValues.length ? this.selectedValues : null);
      },
      isSelected(id) {
        return this.selectedValues.includes(id);
      }
    }
  }
</script>
