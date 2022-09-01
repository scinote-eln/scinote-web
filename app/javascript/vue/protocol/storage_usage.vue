<template>
  <div class="storage-usage">
    <div class="progress-container">
      <div class="progress-bar" :style="`width:${storagePrecentage}%`"></div>
    </div>
    <span class="progress-message" v-if="this.step.attributes.storage_limit.total > 0">
      {{ i18n.t('protocols.steps.space_used_label', {
                  used: this.step.attributes.storage_limit.used_human,
                  limit: this.step.attributes.storage_limit.total_human
      }) }}
    </span>
    <span class="progress-message" v-else>
      {{ i18n.t('protocols.steps.space_used_label_unlimited', {used: this.step.attributes.storage_limit.used_human}) }}
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
