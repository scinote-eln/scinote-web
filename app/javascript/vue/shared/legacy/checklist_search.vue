<template>
  <checklistSelect
    :class="{
      ['sn-select sn-select--search hover:border-sn-sleepy-grey']: true,
      'sn-select--open': shouldOpen,
      'sn-select--blank': !valueLabel,
      'disabled': disabled
    }"
    :className="className"
    :optionsClassName="optionsClassName"
    :withButtons="withButtons"
    :withEditCursor="withEditCursor"
    :initialSelectedValues="initialSelectedValues"
    :options="currentOptions"
    :placeholder="placeholder"
    :noOptionsPlaceholder="isLoading || isLazyLoading ? i18n.t('general.loading') : noOptionsPlaceholder"
    :disabled="disabled"
    :shouldOpen="shouldOpen"
    :shouldUpdateWithoutValues="shouldUpdateWithoutValues"
    :shouldUpdateOnToggleClose="shouldUpdateOnToggleClose"
    @reached-end="handleReachedEnd"
    @close="shouldOpen = false"
    @update-selected-values="selectedValues = $event"
  >
    <div class="flex w-full" @click="shouldOpen = !shouldOpen">
      <input
        ref="focusElement"
        v-model="query"
        type="text"
        class="sn-select__search-input"
        :placeholder="placeholder"
        @blur="query = ''" />
      <span class="sn-select__value">{{ valueLabel || (placeholder || i18n.t('general.select')) }}</span>
      <i class="sn-icon" :class="{ 'sn-icon-down': !shouldOpen, 'sn-icon-up': shouldOpen}"></i>
    </div>
  </checklistSelect>
</template>

<script>
import checklistSelect from './checklist_select.vue';
import { debounce } from '../debounce';

export default {
  name: 'ChecklistSearch',
  props: {
    withButtons: { type: Boolean, default: false },
    withEditCursor: { type: Boolean, default: false },
    initialSelectedValues: { type: Array, default: () => [] },
    options: { type: Array, default: () => [] },
    placeholder: { type: String },
    noOptionsPlaceholder: { type: String },
    disabled: { type: Boolean, default: false },
    className: { type: String, default: '' },
    optionsClassName: { type: String, default: '' },
    shouldUpdateWithoutValues: { type: Boolean, default: false },
    shouldUpdateOnToggleClose: { type: Boolean, default: false },
    isLoading: { type: Boolean, default: false },
    params: { type: Array, default: () => [] },
    optionsUrl: { type: String, required: true },
    lazyLoadEnabled: { type: Boolean, default: false }
  },
  components: { checklistSelect },
  emits: ['reached-end', 'update-options'],
  data() {
    return {
      query: null,
      currentOptions: null,
      shouldOpen: false,
      nextPage: 1,
      isLazyLoading: false,
      selectedValues: []
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

      if (this.optionsUrl) {
        // reset current options and next page when lazy loading is enabled
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
      if (!this.selectedValues.length) return '';
      if (this.selectedValues.length === 1) {
        return this.currentOptions.find(({ id }) => id === this.selectedValues[0])?.label;
      }
      return `${this.selectedValues.length} ${this.i18n.t('general.options_selected')}`;
    }
  },
  methods: {
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
        url: this.optionsUrl,
        data: {
          ...(this.query && { query: this.query }),
          ...(this.lazyLoadEnabled && this.nextPage && { page: this.nextPage }),
          ...this.params
        },
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
