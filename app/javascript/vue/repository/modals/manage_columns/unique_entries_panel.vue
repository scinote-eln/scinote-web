<template>
  <div class="flex flex-col gap-4 p-4 mt-6 rounded bg-sn-super-light-grey" :data-e2e="`e2e-CT-invItems-manageColumns-${e2eValue}`">
    <div class="flex items-center gap-4">
      <div class="grow font-bold">{{ title }}</div>
      <span class="sci-toggle-checkbox-container shrink-0">
        <input type="checkbox"
               class="sci-toggle-checkbox"
               :checked="enforce"
               @change="$emit('update:enforce', $event.target.checked)"
               :data-e2e="`e2e-TG-invItems-manageColumns-${e2eValue}`" />
        <span class="sci-toggle-checkbox-label"></span>
      </span>
    </div>
    <template v-if="enforce">
      <label v-for="option in caseOptions" :key="option.value"
             class="flex items-center gap-3 mb-0 font-normal cursor-pointer">
        <span class="sci-radio-container">
          <input type="radio"
                 class="sci-radio"
                 :name="`${e2eValue}-case-sensitive`"
                 :value="option.value"
                 :checked="caseSensitive === option.value"
                 @change="$emit('update:caseSensitive', option.value)"
                 :data-e2e="`e2e-RB-invItems-manageColumns-${e2eValue}-${option.e2e}`" />
          <span class="sci-radio-label"></span>
        </span>
        {{ option.label }}
      </label>
    </template>
  </div>
</template>

<script>
// Toggle for enforcing unique values with a case sensitivity choice (used by the Name and Text columns)
export default {
  name: 'UniqueEntriesPanel',
  props: {
    title: { type: String, required: true },
    enforce: { type: Boolean, default: false },
    caseSensitive: { type: Boolean, default: true },
    e2eValue: { type: String, default: 'uniqueEntries' }
  },
  emits: ['update:enforce', 'update:caseSensitive'],
  computed: {
    caseOptions() {
      return [
        { value: true, label: this.i18n.t('repositories.unique_entries.case_sensitive'), e2e: 'caseSensitive' },
        { value: false, label: this.i18n.t('repositories.unique_entries.case_insensitive'), e2e: 'caseInsensitive' }
      ];
    }
  }
};
</script>
