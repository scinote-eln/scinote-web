<template>
<div v-if="params.data.status" class="py-0.5">
  <SelectDropdown
    :options="params.statusesList"
    :value="params.data.status"
    @change="changeStatus"
    size="xs"
    :borderless="true"
    :optionRenderer="optionRenderer"
    :labelRenderer="optionRenderer"
    :disabled="!params.data.urls.update"
  />
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
      if (option[0] === 'started') {
        color = 'bg-sn-science-blue';
      } else if (option[0] === 'completed') {
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
