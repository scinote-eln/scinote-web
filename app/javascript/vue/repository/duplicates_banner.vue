<template>
  <div class="flex items-center gap-4 shrink-0 whitespace-nowrap rounded-lg bg-sn-background-passion py-2 pl-4 pr-2 text-sn-black"
       data-e2e="e2e-AL-invInventory-duplicates">
    <div class="flex items-center gap-2">
      <i class="sn-icon sn-icon-alert-destructive text-sn-alert-passion"></i>
      <span v-html="i18n.t('repositories.duplicates_banner.message_html', { count: count })"></span>
    </div>
    <div class="flex items-center gap-2 rounded-lg bg-sn-white px-3 py-2">
      <div class="sci-checkbox-container">
        <input
          :id="checkboxId"
          type="checkbox"
          class="sci-checkbox"
          :checked="modelValue"
          :disabled="disabled"
          data-e2e="e2e-CB-invInventory-showDuplicates"
          @change="$emit('update:modelValue', $event.target.checked)"
        />
        <span class="sci-checkbox-label"></span>
      </div>
      <label :for="checkboxId" class="mb-0 font-normal cursor-pointer">
        {{ i18n.t('repositories.duplicates_banner.show_duplicates') }}
      </label>
    </div>
  </div>
</template>

<script>
export default {
  name: 'DuplicatesBanner',
  props: {
    count: { type: Number, required: true },
    modelValue: { type: Boolean, default: false },
    disabled: { type: Boolean, default: false },
    repositoryId: { type: Number, required: true }
  },
  emits: ['update:modelValue'],
  computed: {
    checkboxId() {
      return `show-duplicates-${this.repositoryId}`;
    }
  }
};
</script>
