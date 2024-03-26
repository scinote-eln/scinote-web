<template>
  <Select
    tabindex="0"
    class="sn-select sn-select--search hover:border-sn-sleepy-grey focus:outline-none focus:ring-0 focus:border-sn-sleepy-grey"
    :class="customClass"
    :className="className"
    :optionsClassName="optionsClassName"
    :withEditCursor="withEditCursor"
    :withClearButton="withClearButton"
    :value="value"
    :options="currentOptions"
    :placeholder="placeholder"
    :noOptionsPlaceholder="isLoading || isLazyLoading ? i18n.t('general.loading') : noOptionsPlaceholder"
    v-bind:disabled="disabled"
    @change="change"
    @reached-end="handleReachedEnd"
    @blur="blur"
    @open="open"
    @close="close"
    @focus="focus"
  >
    <input ref="focusElement" v-model="query" type="text" class="sn-select__search-input" :placeholder="searchPlaceholder" />
    <span class="sn-select__value">{{ valueLabel || (placeholder || i18n.t('general.select')) }}</span>
    <i class="sn-icon" :class="{ 'sn-icon-down': !isOpen, 'sn-icon-up': isOpen}"></i>
  </Select>
</template>

<script>
import Select from './select.vue';
import { debounce } from '../debounce';

export default {
  name: 'SelectSearch',
  emits: ['change', 'close', 'open', 'blur', 'update-options', 'reached-end'],
  props: {
    withClearButton: { type: Boolean, default: false },
    withEditCursor: { type: Boolean, default: false },
    value: { type: [String, Number] },
    options: { type: Array, default: () => [] },
    optionsUrl: { type: String },
    placeholder: { type: String },
    searchPlaceholder: { type: String },
    noOptionsPlaceholder: { type: String },
    disabled: { type: Boolean },
    isLoading: { type: Boolean, default: false },
    className: { type: String, default: '' },
    optionsClassName: { type: String, default: '' },
    customClass: { type: String, default: '' },
    lazyLoadEnabled: { type: Boolean },
    params: { type: Array, default: () => [] }
  },
  components: { Select },
  data() {
    return {
      query: null,
      currentOptions: null,
      isOpen: false,
      nextPage: 1,
      isLazyLoading: false
    };
  },
  created() {
    this.currentOptions = this.options;
  },
  watch: {
    query() {
      if (!this.query) {
        this.currentOptions = this.options;
        return;
      }

      if (this.optionsUrlValue) {
        // reset current options and fetch when lazy loding is enabled
        if (this.lazyLoadEnabled) {
          this.currentOptions = [];
          this.isLazyLoading = true;
          this.nextPage = 1;
        }
        this.$nextTick(() => {
          debounce(this.fetchOptions(), 10);
        });
      } else {
        this.currentOptions = this.options.filter((o) => o[1].toLowerCase().includes(this.query.toLowerCase()));
      }
    },
    options() {
      this.currentOptions = this.options;
    }
  },
  computed: {
    valueLabel() {
      const option = this.currentOptions.find((o) => o[0] === this.value);
      return option && option[1];
    },
    optionsUrlValue() {
      if (!this.optionsUrl) return '';

      let url = `${this.optionsUrl}?query=${this.query || ''}`;
      if (this.lazyLoadEnabled && this.nextPage) url = `${url}&page=${this.nextPage}`;
      if (this.params.length) url = `${url}&${this.params.join('&')}`;
      return url;
    }
  },
  methods: {
    focus() {
      this.$refs.focusElement.focus();
    },
    blur() {
      this.isOpen = false;
      this.$emit('blur');
    },
    change(value) {
      this.isOpen = false;
      this.$emit('change', value);
    },
    open() {
      this.isOpen = true;
      this.$emit('open');
    },
    close() {
      this.query = '';
      this.isOpen = false;
      this.$emit('close');
    },
    handleReachedEnd() {
      if (this.query) {
        this.fetchOptions();
      } else {
        this.$emit('reached-end');
      }
    },
    fetchOptions() {
      if (!this.nextPage || !this.optionsUrl) return;

      $.ajax({
        url: this.optionsUrlValue,
        success: (result) => {
          if (this.lazyLoadEnabled) {
            this.nextPage = result.next_page;
            this.$emit('update-options', this.currentOptions, result);
            this.isLazyLoading = false;
            return;
          }
          this.currentOptions = result;
        }
      });
    }
  }
};
</script>
