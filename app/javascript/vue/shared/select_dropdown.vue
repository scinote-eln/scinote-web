<template>
  <div v-click-outside="close"
       @focus="open"
       @keydown="keySelectOptions($event)"
       tabindex="0" class="w-full focus:outline-none "
  >
    <div
      ref="field"
      class="px-3 py-1 border border-solid rounded flex items-center cursor-pointer"
      @click="open"
      :class="[sizeClass, {
        '!border-sn-blue': isOpen,
        '!border-sn-light-grey': !isOpen,
        'bg-sn-sleepy-grey': disabled
      }]"
    >
    <template v-if="!tagsView">
      <template v-if="!isOpen || !searchable">
        <div class="truncate" v-if="labelRenderer && label" v-html="label"></div>
        <div class="truncate" v-else-if="label">{{ label }}</div>
        <div class="text-sn-grey truncate" v-else>
          {{ placeholder || this.i18n.t('general.select_dropdown.placeholder') }}
        </div>
      </template>
      <input type="text"
             ref="search"
             v-else
             v-model="query"
             :placeholder="label || placeholder || this.i18n.t('general.select_dropdown.placeholder')"
             class="w-full border-0 outline-none pl-0 placeholder:text-sn-grey" />
      </template>
      <div v-else class="flex items-center gap-1 flex-wrap">
        <div v-for="tag in tags" class="px-2 py-1 rounded-sm bg-sn-super-light-grey flex items-center gap-1">
          <div class="truncate" v-if="labelRenderer" v-html="tag.label"></div>
          <div class="truncate" v-else>{{ tag.label }}</div>
          <i @click="removeTag(tag.value)" class="sn-icon mini ml-auto sn-icon-close cursor-pointer"></i>
        </div>
        <input type="text"
               ref="search"
               v-if="searchable && isOpen"
               v-model="query"
               :placeholder="tags.length > 0 ? '' : (placeholder || this.i18n.t('general.select_dropdown.placeholder'))"
               :style="{ width: searchInputSize }"
               :class="{ 'pl-2': tags.length > 0 }"
               class="border-0 outline-none pl-0 py-1 placeholder:text-sn-grey" />
        <div v-else-if="tags.length == 0" class="text-sn-grey truncate">
          {{ placeholder || this.i18n.t('general.select_dropdown.placeholder') }}
        </div>
      </div>
      <i v-if="canClear" @click="clear" class="sn-icon ml-auto sn-icon-close"></i>
      <i v-else class="sn-icon ml-auto"
                :class="{ 'sn-icon-down': !isOpen, 'sn-icon-up': isOpen, 'text-sn-grey': disabled}"></i>
    </div>
    <template v-if="isOpen">
      <teleport to="body">
        <div ref="flyout"
            class="sn-select-dropdown bg-white inline-block sn-shadow-menu-sm rounded w-full
                    fixed z-[3000]">
          <div v-if="multiple && withCheckboxes" class="p-2.5 pb-0">
            <div @click="selectAll" :class="sizeClass"
                class="border border-x-0 !border-transparent border-solid !border-b-sn-light-grey
                        py-1.5 px-3  cursor-pointer flex items-center gap-2 shrink-0">
              <div class="sn-checkbox-icon"
                  :class="selectAllState"
              ></div>
              {{ i18n.t('general.select_all') }}
            </div>
          </div>
          <perfect-scrollbar class="p-2.5 flex flex-col max-h-80 relative" :class="{ 'pt-0': withCheckboxes }">
            <template v-for="(option, i) in filteredOptions" :key="option[0]">
              <div
                @click.stop="setValue(option[0])"
                ref="options"
                class="py-1.5 px-3 rounded cursor-pointer flex items-center gap-2 shrink-0"
                :class="[sizeClass, {
                  '!bg-sn-super-light-blue': valueSelected(option[0]) && focusedOption !== i,
                  '!bg-sn-super-light-grey': focusedOption === i ,
                }]"
              >
                <div v-if="withCheckboxes"
                    class="sn-checkbox-icon shrink-0"
                    :class="{
                      'checked': valueSelected(option[0]),
                      'unchecked': !valueSelected(option[0]),
                    }"
                ></div>
                <div class="truncate" v-if="optionRenderer" v-html="optionRenderer(option)"></div>
                <div class="truncate" v-else >{{ option[1] }}</div>
              </div>
            </template>
            <div v-if="filteredOptions.length === 0" class="text-sn-grey text-center py-2.5">
              {{ noOptionsPlaceholder || this.i18n.t('general.select_dropdown.no_options_placeholder') }}
            </div>
          </perfect-scrollbar>
        </div>
      </teleport>
    </template>
  </div>

</template>

<script>
import { vOnClickOutside } from '@vueuse/components';
import FixedFlyoutMixin from './mixins/fixed_flyout.js';
import axios from '../../packs/custom_axios.js';

export default {
  name: 'SelectDropdown',
  props: {
    value: { type: [String, Number, Array] },
    options: { type: Array, default: () => [] },
    optionsUrl: { type: String },
    placeholder: { type: String },
    noOptionsPlaceholder: { type: String },
    fewOptionsPlaceholder: { type: String },
    allOptionsPlaceholder: { type: String },
    optionRenderer: { type: Function },
    labelRenderer: { type: Function },
    disabled: { type: Boolean, default: false },
    size: { type: String, default: 'md' },
    multiple: { type: Boolean, default: false },
    withCheckboxes: { type: Boolean, default: false },
    searchable: { type: Boolean, default: false },
    clearable: { type: Boolean, default: false },
    tagsView: { type: Boolean, default: false },
    urlParams: { type: Object, default: () => ({}) }
  },
  directives: {
    'click-outside': vOnClickOutside
  },
  data() {
    return {
      newValue: null,
      isOpen: false,
      fetchedOptions: [],
      selectAllState: 'unchecked',
      query: '',
      fixedWidth: true,
      focusedOption: null
    };
  },
  mixins: [FixedFlyoutMixin],
  computed: {
    sizeClass() {
      switch (this.size) {
        case 'xs':
          return 'min-h-[36px]';
        case 'sm':
          return 'min-h-[40px]';
        case 'md':
          return 'min-h-[44px]';
        default:
          return 'min-h-[44px]';
      }
    },
    canClear() {
      return this.clearable && this.label && this.isOpen && !this.tagsView;
    },
    rawOptions() {
      if (this.optionsUrl) {
        return this.fetchedOptions;
      }
      return this.options;
    },
    filteredOptions() {
      if (this.query.length > 0 && !this.optionsUrl) {
        return this.rawOptions.filter((option) => (
          option[1].toLowerCase().includes(this.query.toLowerCase())
        ));
      }
      return this.rawOptions;
    },
    label() {
      if (this.multiple) {
        return this.multipleLabel;
      }
      return this.singleLabel;
    },
    tags() {
      if (!this.newValue) return [];

      return this.newValue.map((value) => {
        const option = this.rawOptions.find((i) => i[0] === value);
        return {
          value,
          label: this.renderLabel(option)
        };
      });
    },
    singleLabel() {
      const option = this.rawOptions.find((i) => i[0] === this.newValue);
      return this.renderLabel(option);
    },
    multipleLabel() {
      if (!this.newValue) return false;

      this.selectAllState = 'unchecked';

      if (this.newValue.length === 0) {
        return false;
      }
      if (this.newValue.length === 1) {
        this.selectAllState = 'indeterminate';
        return this.renderLabel(this.rawOptions.find((option) => option[0] === this.newValue[0]));
      }
      if (this.newValue.length === this.rawOptions.length) {
        this.selectAllState = 'checked';
        return this.allOptionsPlaceholder || this.i18n.t('general.select_dropdown.all_options_placeholder');
      }
      this.selectAllState = 'indeterminate';
      return `${this.newValue.length} ${
        this.fewOptionsPlaceholder || this.i18n.t('general.select_dropdown.few_options_placeholder')
      }`;
    },
    valueChanged() {
      if (this.multiple) {
        return !this.compareArrays(this.newValue, this.value);
      }
      return this.newValue !== this.value;
    },
    searchInputSize() {
      let characterCount = 10;

      if (this.tags.length === 0) {
        characterCount = (this.placeholder || this.i18n.t('general.select_dropdown.placeholder')).length;
      }

      if (this.query.length > 0) {
        characterCount = this.query.length;
      }

      return `${(characterCount * 8) + 16}px`;
    }
  },
  mounted() {
    this.newValue = this.value;
    if (!this.newValue && this.multiple) {
      this.newValue = [];
    }
    this.fetchOptions();
  },
  watch: {
    value(newValue) {
      this.newValue = newValue;
    },
    isOpen() {
      if (this.isOpen) {
        this.$nextTick(() => {
          this.setPosition();
          this.$refs.search?.focus();
        });
      }
    },
    query() {
      if (this.optionsUrl) this.fetchOptions();
    }
  },
  methods: {
    renderLabel(option) {
      if (!option) return false;

      if (this.labelRenderer) {
        return this.labelRenderer(option);
      }
      return option[1];
    },
    valueSelected(value) {
      if (!this.newValue) return false;
      if (this.multiple) {
        return this.newValue.includes(value);
      }
      return this.newValue === value;
    },
    open() {
      if (!this.disabled) this.isOpen = true;
    },
    clear() {
      this.newValue = this.multiple ? [] : null;
      this.query = '';
      this.$emit('change', this.newValue);
    },
    close(e) {
      if (e && e.target.closest('.sn-select-dropdown')) return;

      if (!this.isOpen) return;

      this.$nextTick(() => {
        this.isOpen = false;
        if (this.valueChanged) {
          this.$emit('change', this.newValue);
        }
        this.query = '';
      });
    },
    setValue(value) {
      this.query = '';

      if (this.multiple) {
        if (this.newValue.includes(value)) {
          this.newValue = this.newValue.filter((v) => v !== value);
        } else {
          this.newValue = [...this.newValue, value];
        }
      } else {
        this.newValue = value;
        this.$nextTick(() => {
          this.close();
        });
      }
    },
    removeTag(value) {
      this.newValue = this.newValue.filter((v) => v !== value);
      this.$emit('change', this.newValue);
    },
    selectAll() {
      if (this.selectAllState === 'checked') {
        this.newValue = [];
      } else {
        this.newValue = this.rawOptions.map((option) => option[0]);
      }
      this.$emit('change', this.newValue);
    },
    fetchOptions() {
      if (this.optionsUrl) {
        const params = { query: this.query, ...this.urlParams };
        axios.get(this.optionsUrl, { params })
          .then((response) => {
            this.fetchedOptions = response.data.data;
            this.$nextTick(() => {
              this.setPosition();
            });
          });
      }
    },
    compareArrays(arr1, arr2) {
      if (!arr1 || !arr2) return false;
      if (arr1.length !== arr2.length) return false;

      for (let i = 0; i < arr1.length; i += 1) {
        if (!arr2.includes(arr1[i])) return false;
      }
      return true;
    },
    keySelectOptions(e) {
      if (e.key === 'Tab') this.close();
      if (['ArrowDown', 'ArrowUp', 'Enter'].some((key) => e.key === key)) {
        if (e.key === 'ArrowDown') {
          this.focusedOption = this.focusedOption === null ? 0 : this.focusedOption + 1;
          if (this.focusedOption > this.$refs.options.length - 1) this.focusedOption = 0;
        } else if (e.key === 'ArrowUp') {
          this.focusedOption = (this.focusedOption || this.$refs.options.length) - 1;
          if (this.focusedOption < 0) this.focusedOption = this.$refs.options.length - 1;
        } else if (e.key === 'Enter' && this.focusedOption !== null) {
          this.setValue(this.filteredOptions[this.focusedOption][0]);
        }
      }
      if (this.$refs.options) {
        this.$refs.options[this.focusedOption]?.scrollIntoView({ block: 'nearest' });
      }
    }
  }
};
</script>
