<template>
  <div class="grid grid-cols-2 gap-4 items-start">
    <div class="bg-sn-white p-4 rounded-lg">
      <AnalyticalReportTemplateDataInputs
        :protocolId="protocolId"
      ></AnalyticalReportTemplateDataInputs>
    </div>

    <div class="flex flex-col bg-sn-white p-4 rounded-lg gap-4">
      <div class="flex justify-between items-center">
        <div class="text-xl font-semibold"> {{ i18n.t('protocols.analytical_reports.title') }}</div>
        <button v-if="editable" class="btn btn-primary icon-btn" @click="protocolAnalyticalReportTemplateModal = true">
          <i class="sn-icon sn-icon-new-task"></i>
          {{ i18n.t('protocols.analytical_reports.new_template') }}
        </button>
      </div>
      <div v-for="template in templates" class="text-lg font-semibold bg-sn-super-light-grey p-4 rounded">
        <div>{{ template.name }}</div>
      </div>
    </div>
  </div>
  <CreateAnalyticalReportTemplateModal v-if="protocolAnalyticalReportTemplateModal"
                                       :protocolId="protocolId"
                                       @templateCreated="reloadTemplates()"
                                       @close="protocolAnalyticalReportTemplateModal = false"/>
</template>

<script>
import axios from '../../packs/custom_axios.js';
import AnalyticalReportTemplateDataInputs from './analytical_reports/data_inputs.vue';
import CreateAnalyticalReportTemplateModal from './modals/create_analytical_report_template.vue'
import {
  protocol_analytical_reports_path
} from '../../routes.js'

export default {
  name: 'ProtocolAnalyticalReports',
  props: {
    protocolId: {
      required: true
    },
    editable: {
      default: false
    }
  },
  components: {
    AnalyticalReportTemplateDataInputs,
    CreateAnalyticalReportTemplateModal
  },
  data() {
    return {
      protocolAnalyticalReportTemplateModal: false,
      templates: []
    }
  },
  created() {
    this.fetchTemplates();
  },
  computed: {
    loadUrl() {
      return protocol_analytical_reports_path(this.protocolId);
    }
  },
  methods: {
    fetchTemplates() {
      axios.get(this.loadUrl).then((response) => {
        this.templates = response.data.templates;
      });
    },
    reloadTemplates() {
      this.protocolAnalyticalReportTemplateModal = false;
      this.fetchTemplates();
    }
  }
};
</script>
