<template>
  <div v-click-outside="close"
       @focus="open"
       @keydown="keySelectOptions($event)"
       tabindex="0" class="w-full focus:outline-none"
       :data-e2e="e2eValue"
  >
    <div
      ref="field"
      class="px-3 py-1 rounded flex items-center cursor-pointer"
      @click="open"
      :class="[{
        'border border-solid': !borderless,
        '!border-sn-science-blue': isOpen && !borderless,
        '!border-sn-light-grey': !isOpen && !borderless,
        'bg-sn-super-light-grey': disabled,
        'pl-0': borderless
      }]"
      :style="sizeStyle"
    >
    <template v-if="!tagsView">
      <template v-if="!isOpen || !searchable">
        <div v-if="labelRendererType == 'object' && !multiple && this.rawOptions && Object.keys(this.rawOptions).length > 0 && this.newValue && Object.keys(this.newValue).length > 0">
          <component :is="labelRenderer"
                     :option="this.rawOptions.find((i) => i[0] === this.newValue)" />
        </div>
        <div v-else-if="labelRendererType == 'object' && multiple && this.newValue && this.newValue.length === 1">
          <component :is="labelRenderer"
                     :option="this.rawOptions.find((i) => i[0] === this.newValue[0])" />
        </div>
        <div class="truncate" v-else-if="labelRendererType == 'function' && label" v-html="label"></div>
        <div class="truncate" v-else-if="label">{{ label }}</div>
        <div class="text-sn-grey truncate" v-else>
          {{ placeholder || this.i18n.t('general.select_dropdown.placeholder') }}
        </div>
      </template>
      <input type="text"
             ref="search"
             v-else
             v-model="query"
             :placeholder="placeholderRender"
             @keyup="reloadItems"
             @change.stop
             class="w-full bg-transparent border-0 outline-none pl-0 placeholder:text-sn-grey" />
      </template>
      <div v-else class="flex items-center gap-1 flex-wrap">
        <div v-for="tag in tags" class="sci-tag bg-sn-super-light-grey" :class="tagTextColor(tag.option[2]?.color)" :style="{ backgroundColor: tag.option[2]?.color }" :key="tag.value">
          <div v-if="labelRendererType == 'object'">
            <component :is="labelRenderer" :option="tag.option" />
          </div>
          <div class="text-block" v-else>{{ tag.label }}</div>
          <i @click="removeTag(tag.value)" class="sn-icon mini ml-auto sn-icon-close cursor-pointer"></i>
        </div>
        <input type="text"
               ref="search"
               v-if="searchable && isOpen"
               v-model="query"
               :placeholder="tags.length > 0 ? '' : (placeholder || this.i18n.t('general.select_dropdown.placeholder'))"
               :style="{ width: searchInputSize }"
               :class="{ 'pl-2': tags.length > 0 }"
               @change.stop
               class="border-0 outline-none pl-0 py-1 placeholder:text-sn-grey" />
        <div v-else-if="tags.length == 0" class="text-sn-grey truncate">
          {{ placeholder || this.i18n.t('general.select_dropdown.placeholder') }}
        </div>
      </div>
      <i v-if="canClear" @click="clear" class="sn-icon ml-auto sn-icon-close"></i>
      <i v-else class="sn-icon ml-auto" @click="handleClickArrow"
                :class="{ 'sn-icon-down pointer-events-none': !isOpen, 'sn-icon-up': isOpen, 'text-sn-grey': disabled}"></i>
    </div>
    <template v-if="isOpen">
      <teleport to="body">
        <div ref="flyout"
          class="sn-select-dropdown bg-white inline-block sn-shadow-menu-sm rounded w-full fixed z-[3000]"
          :data-e2e="`${e2eValue}-dropdownOptions`"
        >
          <div v-if="multiple && withCheckboxes" class="p-2.5 pb-0">
            <div @click="selectAll" :style="sizeStyle"
                class="border border-x-0 !border-transparent border-solid !border-b-sn-light-grey
                        py-1.5 px-3  cursor-pointer flex items-center gap-2 shrink-0">
              <div class="sn-checkbox-icon"
                  :class="selectAllState"
              ></div>
              {{ i18n.t('general.select_all') }}
            </div>
          </div>
          <div ref="scrollContainer" class="p-2.5 flex flex-col max-h-80 relative overflow-y-auto" :class="{ 'pt-0': withCheckboxes }">
            <template v-for="(option, i) in filteredOptions" :key="option[0]">
              <div
                @click.stop="setValue(option[0])"
                ref="options"
                :title="option[2]?.tooltip || option[1]"
                class="py-1.5 px-3 rounded cursor-pointer flex items-center gap-2 shrink-0 hover:bg-sn-super-light-grey"
                :class="[{
                  '!bg-sn-super-light-blue': valueSelected(option[0]) && focusedOption !== i,
                  '!bg-sn-super-light-grey': focusedOption === i ,
                }]"
                :style="sizeStyle"
              >
                <div v-if="withCheckboxes"
                    class="sn-checkbox-icon shrink-0"
                    :class="{
                      'checked': valueSelected(option[0]),
                      'unchecked': !valueSelected(option[0]),
                    }"
                ></div>
                <div v-if="optionRendererType == 'object'" >
                  <component :is="optionRenderer"
                             :option="option" />
                </div>
                <div class="truncate w-full" v-else-if="optionRendererType == 'function'" v-html="optionRenderer(option)"></div>
                <div class="truncate" v-else >{{ option[1] }}</div>
              </div>
            </template>
            <div v-if="filteredOptions.length === 0" class="text-sn-grey text-center py-2.5">
              {{ noOptionsPlaceholder || this.i18n.t('general.select_dropdown.no_options_placeholder') }}
            </div>
          </div>
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
    optionRenderer: { type: [Function, Object] },
    labelRenderer: { type: [Function, Object] },
    disabled: { type: Boolean, default: false },
    size: { type: String, default: 'md' },
    borderless: { type: Boolean, default: false },
    multiple: { type: Boolean, default: false },
    withCheckboxes: { type: Boolean, default: false },
    searchable: { type: Boolean, default: false },
    clearable: { type: Boolean, default: false },
    tagsView: { type: Boolean, default: false },
    urlParams: { type: Object, default: () => ({}) },
    e2eValue: { type: String, default: '' },
    ajaxMethod: { type: String, default: 'get' },
    oneLineLabel: { type: Boolean, default: false }
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
      focusedOption: null,
      skipQueryCallback: false,
      nextPage: 1,
      totalOptionsCount: this.options.length
    };
  },
  mixins: [FixedFlyoutMixin],
  computed: {
    placeholderRender() {
      if (this.searchable && this.labelRenderer && this.label) {
        return '';
      }

      return this.label || this.placeholder || this.i18n.t('general.select_dropdown.placeholder');
    },
    sizeStyle() {
      switch (this.size) {
        case 'xs':
          return this.oneLineLabel ? 'height: 36px' : 'min-height: 36px';
        case 'sm':
          return this.oneLineLabel ? 'height: 40px' : 'min-height: 40px';
        case 'md':
          return this.oneLineLabel ? 'height: 44px' : 'min-height: 44px';
        default:
          return this.oneLineLabel ? 'height: 44px' : 'min-height: 44px';
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

      this.selectAllState = 'indeterminate';
      if (this.newValue.length === 0) {
        this.selectAllState = 'unchecked';
      } else if (this.newValue.length === this.rawOptions.length) {
        this.selectAllState = 'checked';
      }

      return this.newValue.map((value) => {
        const option = this.rawOptions.find((i) => i[0] === value);
        return {
          value,
          option,
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
      if (this.newValue.length === 1 && this.totalOptionsCount > 1) {
        this.selectAllState = 'indeterminate';
        return this.renderLabel(this.rawOptions.find((option) => option[0] === this.newValue[0]));
      }
      if (this.newValue.length === this.totalOptionsCount) {
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
    },
    optionRendererType() {
      if (!this.optionRenderer) return null;

      return typeof this.optionRenderer;
    },
    labelRendererType() {
      if (!this.labelRenderer) return null;

      return typeof this.labelRenderer;
    }
  },
  mounted() {
    if (this.optionsUrl) {
      this.fetchedOptions = [];
      this.nextPage = 1;
      this.fetchOptions();
    }

    this.newValue = this.value;
    if (!this.newValue && this.multiple) {
      this.newValue = [];
    }
  },
  watch: {
    value(newValue) {
      this.newValue = newValue;
    },
    isOpen(newVal) {
      this.$emit('isOpen', newVal);
      if (this.isOpen) {
        this.$nextTick(() => {
          this.setPosition();
          this.$refs.search?.focus();
          this.$refs.scrollContainer.addEventListener('scroll', this.loadNextPage);
        });
      }
    },
    urlParams: {
      handler(oldVal, newVal) {
        if (!this.compareObjects(oldVal, newVal)) {
          this.reloadItems();
        }
      },
      deep: true
    }
  },
  methods: {
    reloadItems() {
      this.fetchedOptions = [];
      this.nextPage = 1;
      this.fetchOptions();
    },
    loadNextPage() {
      const container = this.$refs.scrollContainer;
      if (this.nextPage && container.scrollTop + container.clientHeight >= container.scrollHeight) {
        this.fetchOptions();
      }
    },
    renderLabel(option) {
      if (!option) return false;
      if (this.labelRendererType == 'function') {
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
      if (this.disabled || this.isOpen) return;

      this.isOpen = true;

      if (this.optionsUrl) {
        this.fetchedOptions = [];
        this.nextPage = 1;
        this.fetchOptions();
      }
    },
    clear() {
      this.newValue = this.multiple ? [] : null;
      this.query = '';
      this.$emit('change', this.newValue, '');
    },
    close(e) {
      if (e && e.target.closest('.sn-select-dropdown')) return;

      if (!this.isOpen) return;

      this.$nextTick(() => {
        this.isOpen = false;
        this.$emit('close');
        if (this.valueChanged) {
          this.$emit('change', this.newValue, this.getLabels(this.newValue));
        }
        this.query = '';
      });
    },
    setValue(value) {
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
      this.$emit('change', this.newValue, this.getLabels(this.newValue));
    },
    selectAll() {
      if (this.selectAllState === 'checked') {
        this.newValue = [];
      } else {
        this.newValue = this.rawOptions.map((option) => option[0]);
      }
      this.$emit('change', this.newValue, this.getLabels(this.newValue));
    },
    getLabels(value) {
      if (typeof value === 'string' || typeof value === 'number') {
        const option = this.rawOptions.find((i) => i[0] === value);
        return option[1];
      }
      return this.rawOptions.filter((option) => value.includes(option[0])).map((option) => option[1]);
    },
    fetchOptions() {
      if (this.optionsUrl) {
        const params = { query: this.query, page: this.nextPage, ...this.urlParams };

        let request = {};

        if (this.ajaxMethod.toLowerCase() === 'get') {
          request = { method: 'get', url: this.optionsUrl, params };
        } else {
          request = { method: 'post', url: this.optionsUrl, data: params };
        }

        axios(request)
          .then((response) => {
            let options = response.data.data;

            // Convert object options to array options
            options = options.map((option) => {
              if (Array.isArray(option)) return option;

              return [option.id, option.name, option];
            });

            if (response.data.paginated) {
              this.fetchedOptions = [...this.fetchedOptions, ...options];
              this.nextPage = response.data.next_page;
            } else {
              this.fetchedOptions = options;
            }

            if (this.fetchedOptions.length > this.totalOptionsCount) {
              this.totalOptionsCount = this.fetchedOptions.length;
            }

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
    },
    compareObjects(o1, o2) {
      const normalizedObj1 = Object.fromEntries(Object.entries(o1).sort(([k1], [k2]) => k1.localeCompare(k2)));
      const normalizedObj2 = Object.fromEntries(Object.entries(o2).sort(([k1], [k2]) => k1.localeCompare(k2)));
      return JSON.stringify(normalizedObj1) === JSON.stringify(normalizedObj2);
    },
    handleClickArrow(e) {
      if (this.isOpen) {
        e.stopPropagation();
        this.close();
      }
    },
    tagTextColor(color) {
      return window.isColorBright(color) ? 'text-black' : 'text-white';
    }
  }
};
</script>
