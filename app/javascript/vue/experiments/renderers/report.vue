<template>
  <div v-if="params.data.analytical_report.id" class="flex items-center gap-2">
    <i class="sn-icon sn-icon-file-pdf text-sn-grey"></i>
    <a href="#" @click.prevent="openReportModal(params.data)">
      {{ params.data.analytical_report.name }}
    </a>
  </div>
  <div v-else-if="params.data.permissions.manage ">
    <a href="#" @click.prevent="">
      {{ i18n.t('experiments.reports.generate_button') }}
    </a>
  </div>
</template>
<script>

export default {
  name: 'ReportRenderer',
  props: {
    params: {
      required: true
    }
  },
  methods: {
    openReportModal(value) {
      this.params.dtComponent.$emit('openReportModal', value);
    }
  }
};
</script>
