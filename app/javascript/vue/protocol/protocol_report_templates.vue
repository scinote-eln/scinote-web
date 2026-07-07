<template>
  <div class="grid grid-cols-2 gap-4 items-start">
    <div class="bg-sn-white p-4 rounded-lg">
      <ProtocolReportTemplateDataInputs
        :protocolId="protocolId"
      ></ProtocolReportTemplateDataInputs>
    </div>

    <div class="flex flex-col bg-sn-white p-4 rounded-lg gap-4">
      <div class="flex justify-between items-center">
        <div class="text-xl font-semibold"> {{ i18n.t('protocols.report_template.title') }}</div>
        <button v-if="editable" class="btn btn-primary icon-btn" @click="protocolReportTemplateModal = true">
          <i class="sn-icon sn-icon-new-task"></i>
          {{ i18n.t('protocols.report_template.new_template') }}
        </button>
      </div>
      <div v-for="template in templates" class="text-lg font-semibold bg-sn-super-light-grey p-4 rounded">
        <div>{{ template.name }}</div>
      </div>
    </div>
  </div>
  <CreateProtocolReportTemplateModal v-if="protocolReportTemplateModal"
                                       :protocolId="protocolId"
                                       @templateCreated="reloadTemplates()"
                                       @close="protocolReportTemplateModal = false"/>
</template>

<script>
import axios from '../../packs/custom_axios.js';
import ProtocolReportTemplateDataInputs from './protocol_report_templates/data_inputs.vue';
import CreateProtocolReportTemplateModal from './modals/create_protocol_report_template.vue'
import {
  protocol_protocol_report_templates_path
} from '../../routes.js'

export default {
  name: 'ProtocolReportTemplates',
  props: {
    protocolId: {
      required: true
    },
    editable: {
      default: false
    }
  },
  components: {
    ProtocolReportTemplateDataInputs,
    CreateProtocolReportTemplateModal
  },
  data() {
    return {
      protocolReportTemplateModal: false,
      templates: []
    }
  },
  created() {
    this.fetchTemplates();
  },
  computed: {
    loadUrl() {
      return protocol_protocol_report_templates_path(this.protocolId);
    }
  },
  methods: {
    fetchTemplates() {
      axios.get(this.loadUrl).then((response) => {
        this.templates = response.data.templates;
      });
    },
    reloadTemplates() {
      this.protocolReportTemplateModal = false;
      this.fetchTemplates();
    }
  }
};
</script>
