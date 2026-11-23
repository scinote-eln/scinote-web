<template>
  <UniqueEntriesPanel
    v-model:enforce="enforceUnique"
    v-model:caseSensitive="caseSensitive"
    :title="i18n.t('repositories.unique_entries.title')"
    e2eValue="enforceUniqueEntries"
  />
</template>

<script>
import UniqueEntriesPanel from '../unique_entries_panel.vue';

export default {
  name: 'TextColumnType',
  components: { UniqueEntriesPanel },
  props: {
    column: { type: Object, default: null }
  },
  data() {
    const metadata = this.column?.cellRendererParams?.metadata || {};

    return {
      enforceUnique: !!this.column?.cellRendererParams?.enforceUnique,
      caseSensitive: metadata.unique_case_sensitive !== false
    };
  },
  methods: {
    valid() {
      return true;
    },
    payload() {
      return { enforce_unique: this.enforceUnique, unique_case_sensitive: this.caseSensitive };
    }
  }
};
</script>
