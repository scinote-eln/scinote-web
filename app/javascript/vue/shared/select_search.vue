<template>
  <Select class="sn-select--search" :options="currentOptions" :placeholder="placeholder" :disabled="disabled" @change="change" @blur="blur" @open="open" @close="close">
    <input ref="focusElement" v-model="query" type="text" class="sn-select__search-input" :placeholder="searchPlaceholder" />
    <span class="sn-select__value">{{ valueLabel || (placeholder || i18n.t('general.select')) }}</span>
    <span class="sn-select__caret caret"></span>
  </Select>
</template>

<script>
  import Select from './select.vue'

  export default {
    name: 'SelectSearch',
    props: {
      options: { type: Array, default: () => [] },
      optionsUrl: { type: String },
      placeholder: { type: String },
      searchPlaceholder: { type: String },
      disabled: { type: Boolean }
    },
    components: { Select },
    data() {
      return {
        value: null,
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
      blur() {
        this.isOpen = false;
        this.$emit('blur');
      },
      change(value) {
        this.value = value;
        this.isOpen = false;
        this.$emit('change', this.value);
      },
      open() {
        this.isOpen = true;
        this.$emit('open');
      },
      close() {
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
