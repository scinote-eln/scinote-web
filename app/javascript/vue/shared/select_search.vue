<template>
  <Select
    class="sn-select sn-select--search hover:border-sn-sleepy-grey"
    :class="customClass"
    :className="className"
    :optionsClassName="optionsClassName"
    :withEditCursor="withEditCursor"
    :withClearButton="withClearButton"
    :value="value"
    :options="currentOptions"
    :placeholder="placeholder"
    :noOptionsPlaceholder="isLoading ? i18n.t('general.loading') : noOptionsPlaceholder"
    v-bind:disabled="disabled"
    @change="change"
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
  import Select from './select.vue'

  export default {
    name: 'SelectSearch',
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
      customClass: { type: String, default: '' }
    },
    components: { Select },
    data() {
      return {
        query: null,
        currentOptions: null,
        isOpen: false
      }
    },
    created() {
      this.currentOptions = this.options;
    },
    watch: {
      query() {
        if(!this.query) {
          this.currentOptions = this.options;
          return;
        }

        if (this.optionsUrl) {
          this.fetchOptions();
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
        let option = this.currentOptions.find((o) => o[0] === this.value);
        return option && option[1];
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
      fetchOptions() {
        $.get(`${this.optionsUrl}?query=${this.query || ''}`,
          (data) => {
            this.currentOptions = data;
          }
        );
      }
    }
  }
</script>
