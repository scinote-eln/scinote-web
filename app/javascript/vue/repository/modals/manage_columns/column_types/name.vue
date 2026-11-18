<template>
  <UniqueEntriesPanel
    v-model:enforce="enforceUnique"
    v-model:caseSensitive="caseSensitive"
    :title="i18n.t('repositories.unique_item_names.enforce_label')"
    e2eValue="enforceUniqueItemNames"
  />
</template>

<script>
import UniqueEntriesPanel from '../unique_entries_panel.vue';

// Settings of the system Name column; saved on the inventory, not on a repository column
export default {
  name: 'NameColumnType',
  components: { UniqueEntriesPanel },
  props: {
    enforceUniqueItemNames: { type: Boolean, default: false },
    uniqueItemNamesCaseSensitive: { type: Boolean, default: false }
  },
  data() {
    return {
      enforceUnique: this.enforceUniqueItemNames,
      caseSensitive: this.uniqueItemNamesCaseSensitive
    };
  },
  methods: {
    payload() {
      return {
        enforce_unique_item_names: this.enforceUnique,
        unique_item_names_case_sensitive: this.caseSensitive
      };
    }
  }
};
</script>
