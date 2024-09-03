<template>
  <template v-if="params.data.provisioning_status === 'in_progress'">
    <span class="flex gap-2 items-center">
      <div :title="this.i18n.t('experiments.duplicate_tasks.duplicating')"
           class="loading-overlay w-6 h-6 !relative shrink-0" data-toggle="tooltip" data-placement="right"></div>
      <span class="truncate">{{ params.data.name }}</span>
    </span>
  </template>
  <template v-else>
    <a :href="params.data.urls.show" :title="params.data.name" >
      <span class="truncate">{{ params.data.name }}</span>
    </a>
  </template>
</template>

<script>
import axios from '../../../packs/custom_axios.js';

export default {
  name: 'NameRenderer',
  props: {
    params: {
      required: true
    }
  },
  created() {
    if (this.params.data.provisioning_status === 'in_progress') {
      setTimeout(() => {
        this.checkProvisioning();
      }, 5000);
    }
  },
  methods: {
    checkProvisioning() {
      if (this.params.data.provisioning_status === 'done') return;
      axios.get(this.params.data.urls.provisioning_status).then((response) => {
        const provisioningStatus = response.data.provisioning_status;
        if (provisioningStatus === 'done') {
          this.params.dtComponent.$emit('reloadTable', null, [this.params.data]);
        } else {
          setTimeout(() => {
            this.checkProvisioning();
          }, 5000);
        }
      });
    }
  }
};
</script>
