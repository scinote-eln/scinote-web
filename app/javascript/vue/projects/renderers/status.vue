<template>
<div v-if="params.data.status">
  <div v-if="params.data.urls.update" class="py-0.5">
    <SelectDropdown
      :options="params.statusesList"
      :value="params.data.status"
      @change="changeStatus"
      size="xs"
      :borderless="true"
      :oneLineLabel="true"
      :optionRenderer="optionRenderer"
      :labelRenderer="optionRenderer"
    />
  </div>
  <div v-else class="flex items-center gap-2 py-0.5">
    <div class="w-3 h-3 rounded-full"
        :class="{
          'bg-sn-grey-500': params.data.status === 'not_started',
          'bg-sn-science-blue': params.data.status === 'in_progress',
          'bg-sn-alert-green': params.data.status === 'done'
        }"></div>
      <span class="truncate">
        {{ this.i18n.t(`projects.index.status.${params.data.status}`) }}
      </span>
  </div>
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
    optionRenderer(option) {
      let color = 'bg-sn-grey-500';
      if (option[0] === 'in_progress') {
        color = 'bg-sn-science-blue';
      } else if (option[0] === 'done') {
        color = 'bg-sn-alert-green';
      }

      return `
        <div class="flex items-center gap-2">
          <div class="${color} w-3 h-3 rounded-full"></div>
          <span>${option[1]}</span>
        </div>`;
    },
    changeStatus(newStatus) {
      this.params.dtComponent.$emit('changeStatus', newStatus, this.params);
    }
  }
};
</script>
