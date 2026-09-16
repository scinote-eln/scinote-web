<template>
  <div v-if="generating" class="text-sn-grey">
    {{ i18n.t('experiments.reports.generating_label') }}
  </div>
  <div v-else-if="params.data.analytical_report.id" class="flex items-center gap-2">
    <i class="sn-icon sn-icon-file-pdf text-sn-grey"></i>
    <a href="#" @click.prevent="openReportModal(params.data)">
      {{ params.data.analytical_report.name }}
    </a>
  </div>
  <div v-else-if="params.data.permissions.manage ">
    <a href="#" @click.prevent="openGenerateReportModal(params.data)">
      {{ i18n.t('experiments.reports.generate_button') }}
    </a>
  </div>
</template>
<script>

import ActionCableConsumer from '../../../channels/consumer';

export default {
  name: 'ReportRenderer',
  props: {
    params: {
      required: true
    }
  },
  data() {
    return {
      experimentReportGenerationsChannel: null,
      generating: false
    };
  },
  mounted() {
    this.generating = this.params.data.analytical_report.generating;
    if (this.params.data.analytical_report.generating && !this.experimentReportGenerationsChannel) {
      this.experimentReportGenerationsChannel = ActionCableConsumer.subscriptions.create(
        { channel: 'ExperimentReportGenerationsChannel', experiment_id: this.params.data.id },
        {
          received: (data) => {
            if(data?.generating_report !== undefined) {
              this.generating = data.generating_report;
            }
          }
        }
      );
    }
  },
  beforeUnmount() {
    if (this.experimentReportGenerationsChannel) ActionCableConsumer.subscriptions.remove(this.experimentReportGenerationsChannel);
  },
  methods: {
    openReportModal(value) {
      this.params.dtComponent.$emit('openReportModal', value);
    },
    openGenerateReportModal(value) {
      this.params.dtComponent.$emit('openGenerateReportModal', null, [value]);
    }
  }
};
</script>
