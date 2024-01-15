<template>
  <div class="storage-usage">
    <div class="progress-container">
      <div class="progress-bar" :style="`width:${storagePrecentage}%`"></div>
    </div>
    <span class="progress-message" v-if="this.parent.attributes.storage_limit.total > 0">
      {{ i18n.t('protocols.steps.space_used_label', {
                  used: this.parent.attributes.storage_limit.used_human,
                  limit: this.parent.attributes.storage_limit.total_human
      }) }}
    </span>
    <span class="progress-message" v-else>
      {{ i18n.t('protocols.steps.space_used_label_unlimited', {used: this.parent.attributes.storage_limit.used_human}) }}
    </span>
  </div>
</template>
<script>
export default {
  name: 'StorageUsage',
  props: {
    parent: {
      type: Object,
      required: true
    }
  },
  computed: {
    storagePrecentage() {
      const { used } = this.parent.attributes.storage_limit;
      const { total } = this.parent.attributes.storage_limit;
      return ((used / total) * 100);
    }
  }
};
</script>
