<template>
  <div class="storage-usage">
    <div class="progress-container">
      <div class="progress-bar" :style="`width:${storagePrecentage}%`"></div>
    </div>
    <span v-if="this.step.attributes.storage_limit.total > 0">
      {{ `${this.step.attributes.storage_limit.used_human} / ${this.step.attributes.storage_limit.total_human} Space used`}}
    </span>
    <span v-else>
      {{ `${this.step.attributes.storage_limit.used_human} / Unlimited Space used`}}
    </span>
  </div>
</template>
<script>
  export default {
    name: 'StorageUsage',
    props: {
      step: {
        type: Object,
        required: true,
      },
    },
    computed: {
      storagePrecentage() {
        let used = this.step.attributes.storage_limit.used;
        let total = this.step.attributes.storage_limit.total;
        return ((used / total) * 100);
      }
    }
  }
</script>
