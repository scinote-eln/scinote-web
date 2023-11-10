<template>
  <div class="w-full relative" ref="container" v-click-outside="{ handler: 'close', exclude: [] }">
    <button ref="focusElement"
            class="btn flex justify-between items-center w-full outline-none border-[1px] bg-white rounded p-2 pl-4
                  font-inter text-sm font-normal leading-5"
            :class="{
              'sci-cursor-edit': !isOpen && withEditCursor,
              'border-sn-light-grey hover:border-sn-sleepy-grey': !isOpen,
              'border-sn-science-blue': isOpen
            }"
            :disabled="disabled"
            @click="toggle">
      <span>{{ valueLabel }}</span>
      <i class="sn-icon" :class="{ 'sn-icon-down': !isOpen, 'sn-icon-up': isOpen}"></i>
    </button>
    <perfect-scrollbar ref="optionsContainer"
                       :style="optionPositionStyle"
                       class="relative scroll-container p-2.5 pt-0 z-10 bg-white rounded border-[1px] border-sn-light-grey shadow-flyout-shadow max-h-[25rem]"
                       :class="{
                         'block': isOpen,
                         'hidden': !isOpen
                       }">
      <div v-if="withButtons" class="sticky z-10 top-0 bg-white">
        <div class="pb-1 pt-2.5 rounded flex gap-1 justify-start items-center">
          <div class="btn btn-light !text-xs active:bg-sn-super-light-blue"
               @click="selectedValues = []"
               :class="{
                 'disabled cursor-default': !selectedValues.length,
                 'cursor-pointer': selectedValues.length
               }"
              >{{ i18n.t('general.clear') }}</div>
          <div class="btn btn-light !text-xs active:bg-sn-super-light-blue"
               @click="selectedValues = options.map(option => option.id)"
               :class="{
                'disabled cursor-default': options.length === selectedValues.length,
                'cursor-pointer': options.length !== selectedValues.length}">
               {{ i18n.t('general.select_all') }}
          </div>
        </div>
      </div>
      <div v-if="options.length" class="flex flex-col gap-[1px]">
        <div v-for="option in options"
             :key="option.id"
             class="p-3 rounded hover:bg-sn-super-light-grey cursor-pointer flex gap-1 justify-start">
          <div class="sci-checkbox-container">
            <input v-model="selectedValues" :value="option.id" :id="option.id" type="checkbox" class="sci-checkbox project-card-selector mr-1">
            <label :for="option.id" class="sci-checkbox-label"></label>
          </div>
          <span class="text-ellipsis overflow-hidden max-h-[4rem]">{{ option.label }}</span>
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
    name: 'ChecklistSelect',
    comments: { PerfectScrollbar },
    props: {
      withButtons: { type: Boolean, default: false },
      withEditCursor: { type: Boolean, default: false },
      initialSelectedValues: { type: Array, default: () => [] },
      options: { type: Array, default: () => [] },
      placeholder: { type: String },
      noOptionsPlaceholder: { type: String },
      disabled: { type: Boolean, default: false }
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
        if (!this.selectedValues.length) {
          return (this.placeholder || this.i18n.t('general.select'));
        }

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
          this.close();
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
      close() {
        if (!this.isOpen) return;

        this.isOpen = false;
        if (this.selectedValues.length) {
          this.$emit('update', this.selectedValues);
        }
      },
      isSelected(id) {
        return this.selectedValues.includes(id);
      }
    }
  }
</script>
