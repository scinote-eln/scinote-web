<template>
  <div v-if="permissions && customColumns?.length > 0" class="flex flex-col gap-4 w-[350px] h-auto">
    <div v-for="(column, index) in customColumns" :key="column.id" class="flex flex-col gap-4 w-[350px] h-auto relative">
      <component
        :is="column.data_type"
        :key="index"
        :actions="actions"
        :data_type="column.data_type"
        :colId="column.id"
        :colName="column.name"
        :colVal="column.value"
        :repositoryRowId="repositoryRowId"
        :repositoryId="repositoryId"
        :permissions="permissions"
        :updatePath="updatePath"
        :optionsPath="column.options_path"
        :inArchivedRepositoryRow="inArchivedRepositoryRow"
        :decimals="column.decimals"
        :canEdit="permissions.can_manage && !inArchivedRepositoryRow"
        :editingField="editingField"
        @setEditingField="editingField = $event"
        @update="update"
      />
      <div class="sci-divider" :class="{ 'hidden': index === customColumns?.length - 1 }"></div>
    </div>
  </div>
  <div v-else class="text-sn-dark-grey font-inter text-sm font-normal leading-5">
    {{ i18n.t('repositories.item_card.no_custom_columns_label') }}
  </div>
</template>

<script>
import RepositoryStockValue from './repository_values/RepositoryStockValue.vue';
import RepositoryTextValue from './repository_values/RepositoryTextValue.vue';
import RepositoryNumberValue from './repository_values/RepositoryNumberValue.vue';
import RepositoryAssetValue from './repository_values/RepositoryAssetValue.vue';
import RepositoryListValue from './repository_values/RepositoryListValue.vue';
import RepositoryChecklistValue from './repository_values/RepositoryChecklistValue.vue';
import RepositoryStatusValue from './repository_values/RepositoryStatusValue.vue';
import RepositoryDateTimeValue from './repository_values/RepositoryDateTimeValue.vue';
import RepositoryDateTimeRangeValue from './repository_values/RepositoryDateTimeRangeValue.vue';
import RepositoryDateValue from './repository_values/RepositoryDateValue.vue';
import RepositoryDateRangeValue from './repository_values/RepositoryDateRangeValue.vue';
import RepositoryTimeRangeValue from './repository_values/RepositoryTimeRangeValue.vue';
import RepositoryTimeValue from './repository_values/RepositoryTimeValue.vue';

export default {
  name: 'CustomColumns',
  components: {
    RepositoryStockValue,
    RepositoryTextValue,
    RepositoryNumberValue,
    RepositoryAssetValue,
    RepositoryListValue,
    RepositoryChecklistValue,
    RepositoryStatusValue,
    RepositoryDateTimeValue,
    RepositoryDateTimeRangeValue,
    RepositoryDateValue,
    RepositoryDateRangeValue,
    RepositoryTimeRangeValue,
    RepositoryTimeValue
  },
  props: {
    customColumns: { type: Array, default: () => [] },
    permissions: { type: Object, default: () => {} },
    updatePath: { type: String, default: '' },
    repositoryRowId: { type: Number, default: null },
    repositoryId: { type: Number, default: null },
    inArchivedRepositoryRow: { type: Boolean, default: false },
    actions: { type: Object, default: () => {} }
  },
  data() {
    return {
      editingField: null
    };
  },
  methods: {
    update(params) {
      this.$emit('update', params);
    }
  }
};
</script>
