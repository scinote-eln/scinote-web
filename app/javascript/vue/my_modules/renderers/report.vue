<template>
  <div v-if="params.data.analytical_report" class="flex items-center gap-2">
    <i class="sn-icon sn-icon-file-pdf text-sn-grey"></i>
    <a class="file-preview-link file-name"
       :id="`modal_link${params.data.id}`"
       data-no-turbolink="true"
       :data-id="params.data.id"
       :data-gallery-view-id="params.data.experiment_id"
       :data-preview-url="params.data.urls.report">
      {{ params.data.analytical_report }}
    </a>
  </div>
</template>

<script>
import axios from '../../../packs/custom_axios.js';

export default {
  name: 'ReportRenderer',
  props: {
    params: {
      required: true
    }
  }
};
</script>
