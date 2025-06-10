<template>
  <div v-if="params.data.status_cell.editable" class="py-0.5">
    <SelectDropdown
      :options="params.statusesList"
      :value="params.data.status_cell.status"
      @change="changeStatus"
      size="xs"
      :borderless="true"
      :optionRenderer="optionRenderer"
      :labelRenderer="optionRenderer"
    />
  </div>
  <div v-else class="flex items-center gap-2 py-0.5">
    <div class="w-3 h-3 rounded-full"
         :class="this.statusColor(params.data.status_cell.status)"></div>
      <span class="truncate">
        {{ this.i18n.t(`experiments.table.column.status.${params.data.status_cell.status}`) }}
      </span>
  </div>
</template>

<script>

import SelectDropdown from '../../shared/select_dropdown.vue';

export default {
  name: 'StatusRenderer',
  components: {
    SelectDropdown
  },
  props: {
    params: {
      required: true
    }
  },
  methods: {
    statusColor(status) {
      let color = 'bg-sn-grey-500';
      if (status === 'in_progress') {
        color = 'bg-sn-science-blue';
      } else if (status === 'done') {
        color = 'bg-sn-alert-green';
      }

      return color;
    },
    optionRenderer(option) {
      return `
        <div class="flex items-center gap-2">
          <div class="${this.statusColor(option[0])} w-3 h-3 rounded-full"></div>
          <span>${option[1]}</span>
        </div>`;
    },
    changeStatus(newStatus) {
      this.params.dtComponent.$emit('changeStatus', newStatus, this.params);
    }
  }
};
</script>
