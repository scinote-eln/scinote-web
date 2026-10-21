<template>
  <div>
    <div class="flex items-center justify-between">
      <label class="sci-label">{{ label }}</label>
      <div class="text-xs" :class="{ 'text-sn-alert-passion': items.length > limit }">
        <span>{{ items.length }}</span>
        <span>{{ i18n.t('libraries.manange_modal_column.too_many_items_label', { limit }) }}</span>
      </div>
    </div>
    <div class="sci-input-container-v2 mt-2 h-48" :class="{ error: items.length > limit }" :data-error="i18n.t('libraries.manange_modal_column.too_many_items_label', { limit })">
      <textarea
        v-model="text"
        class="sci-input-field w-full"
        :placeholder="placeholder"
        data-e2e="e2e-IF-invItems-manageColumns-items"
      ></textarea>
    </div>
    <div v-if="changeWarning && isEditing" class="bg-sn-background-brittlebush text-sn-alert-brittlebush mt-2 p-2">
      {{ changeWarning }}
    </div>
    <div v-if="description" class="text-sn-grey text-xs mt-2">
      {{ description }}
    </div>
    <div v-if="showPreview" class="mt-4 p-4 rounded bg-sn-super-light-grey">
      <label class="sci-label font-bold">{{ i18n.t('general.preview') }}</label>
      <div class="mt-2">
        <SelectDropdown
          class="bg-sn-white"
          :options="previewOptions"
          :multiple="multiple"
          :withCheckboxes="multiple"
          :clearable="true"
          :searchable="true" />
      </div>
    </div>
  </div>
</template>

<script>
import SelectDropdown from '../../../../shared/select_dropdown.vue';

export default {
  name: 'ItemsEditor',
  components: { SelectDropdown },
  props: {
    modelValue: { type: Array, default: () => [] },
    limit: { type: Number, required: true },
    label: { type: String, required: true },
    placeholder: { type: String, default: '' },
    delimiter: { type: String, default: '\n' },
    splitPattern: { type: [String, RegExp], default: null },
    changeWarning: { type: String, default: null },
    description: { type: String, default: null },
    isEditing: { type: Boolean, default: false },
    showPreview: { type: Boolean, default: true },
    multiple: { type: Boolean, default: false }
  },
  data() {
    return {
      text: this.modelValue.join(this.delimiter)
    };
  },
  computed: {
    items() {
      return this.text
        .split(this.splitPattern || this.delimiter)
        .map((item) => item.trim())
        .filter((item) => item.length > 0);
    },
    previewOptions() {
      return this.items.map((item) => [item, item]);
    }
  },
  watch: {
    items(newItems) {
      this.$emit('update:modelValue', newItems);
    },
    modelValue(newValue) {
      // Only resync the textarea when the change came from outside (e.g. an async
      // load), not when it's just an echo of our own `items` -> emit above.
      if (JSON.stringify(newValue) !== JSON.stringify(this.items)) {
        this.text = newValue.join(this.delimiter);
      }
    }
  },
  methods: {
    valid() {
      return this.items.length > 0 && this.items.length <= this.limit;
    }
  }
};
</script>
