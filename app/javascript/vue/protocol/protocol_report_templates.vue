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
      <div v-for="template in templates" class="flex text-lg font-semibold bg-sn-super-light-grey p-4 rounded justify-between items-center">
        <div>{{ template.name }}</div>
        <div class="flex items-center gap-2">
          <button class="btn btn-secondary icon-btn file-preview-link file-name"
            :id="`modal_link${template.id}`"
            data-no-turbolink="true"
            :data-id="template.id"
            :data-gallery-view-id="protocolId"
            :data-preview-url="template.preview">
            <i class="sn-icon sn-icon-visibility-show"></i>
          </button>
          <button
            v-if="editable"
            class="btn btn-light icon-btn"
            @click.stop="deleteTemplate(template)"
          >
            <i class="sn-icon sn-icon-delete"></i>
          </button>
        </div>
      </div>
    </div>
  </div>
  <CreateProtocolReportTemplateModal v-if="protocolReportTemplateModal"
                                       :protocolId="protocolId"
                                       @templateCreated="reloadTemplates()"
                                       @close="protocolReportTemplateModal = false"/>
  <DeleteModal
    :title="deleteTitle"
    :description="i18n.t('protocols.report_template.delete.description_html')"
    :confirmClass="'btn btn-danger'"
    :confirmText="i18n.t('general.delete')"
    ref="deleteModal"
  ></DeleteModal>
</template>

<script>
import axios from '../../packs/custom_axios.js';
import ProtocolReportTemplateDataInputs from './protocol_report_templates/data_inputs.vue';
import CreateProtocolReportTemplateModal from './modals/create_protocol_report_template.vue'
import DeleteModal from '../shared/confirmation_modal.vue';

import {
  protocol_protocol_report_templates_path,
  protocol_protocol_report_template_path
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
    CreateProtocolReportTemplateModal,
    DeleteModal
  },
  data() {
    return {
      protocolReportTemplateModal: false,
      templates: [],
      deleteTitle: ''
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
    },
    async deleteTemplate(template) {
      this.deleteTitle = this.i18n.t('protocols.report_template.delete.title', { name: template.name })
      const ok = await this.$refs.deleteModal.show();

      if (ok) {
        console.log(this.protocolId, template.id)
        axios.delete(protocol_protocol_report_template_path(this.protocolId, template.id)).then((response) => {
          this.fetchTemplates();
        }).catch((error) => {
          HelperModule.flashAlertMsg(this.i18n.t('general.error'), 'danger');
        });
      }
    }
  }
};
</script>
