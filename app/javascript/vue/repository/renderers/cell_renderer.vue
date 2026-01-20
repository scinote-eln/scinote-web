<template>
  <div v-if="params.value">
    <component :is="params.columnDataType" :params="params" />
  </div>
</template>

<script>
import RepositoryAssetValue from './custom_cells_renderer/asset_value.vue';
import RepositoryChecklistValue from './custom_cells_renderer/checklist_value.vue';
import RepositoryDateValue from './custom_cells_renderer/date_value.vue';
import RepositoryListValue from './custom_cells_renderer/list_value.vue';
import RepositoryTextValue from './custom_cells_renderer/text_value.vue';
import RepositoryNumberValue from './custom_cells_renderer/number_value.vue';
import RepositoryStatusValue from './custom_cells_renderer/status_value.vue';
import RepositoryTimeValue from './custom_cells_renderer/time_value.vue';
import RepositoryDateTimeValue from './custom_cells_renderer/date_time_value.vue';
import RepositoryDateRangeValue from './custom_cells_renderer/date_range_value.vue';
import RepositoryTimeRangeValue from './custom_cells_renderer/time_range_value.vue';
import RepositoryDateTimeRangeValue from './custom_cells_renderer/date_time_range_value.vue';
import RepositoryStockValue from './custom_cells_renderer/stock_value.vue';

export default {
  name: 'CellRenderer',
  props: {
    params: {
      required: true
    }
  },
  components: {
    RepositoryAssetValue,
    RepositoryChecklistValue,
    RepositoryDateValue,
    RepositoryListValue,
    RepositoryTextValue,
    RepositoryNumberValue,
    RepositoryStatusValue,
    RepositoryTimeValue,
    RepositoryDateTimeValue,
    RepositoryDateRangeValue,
    RepositoryTimeRangeValue,
    RepositoryDateTimeRangeValue,
    RepositoryStockValue
  }
};
</script>
