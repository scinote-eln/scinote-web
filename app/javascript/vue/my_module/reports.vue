<template>
  <div class="grid grid-cols-2 gap-4 items-start mt-4">
    <div class="flex flex-col bg-sn-white p-4 rounded-lg gap-4">
      <div class="flex justify-between items-center">
        <div class="text-xl font-semibold"> {{ i18n.t('protocols.report_template.title') }}</div>
      </div>
      <div v-for="template in templates" class="flex justify-between items-center bg-sn-super-light-grey p-4 rounded">
        <div class="text-lg font-semibold">{{ template.name }}</div>
        <div class="flex gap-4">
          <button class="btn btn-secondary icon-btn file-preview-link file-name"
            :id="`modal_link${template.id}`"
            data-no-turbolink="true"
            :data-id="template.id"
            :data-gallery-view-id="myModuleId"
            :data-preview-url="template.preview"
            data-render-tooltip="true"
            :title="i18n.t('general.preview')"
            >
            <i class="sn-icon sn-icon-visibility-show"></i>
          </button>
          <button v-if="editable" class="btn btn-primary icon-btn" @click.stop="generateReport(template.id)">
            <i class="sn-icon sn-icon-reports"></i>
            {{ i18n.t('my_modules.reports.generate_button') }}
          </button>
        </div>
      </div>
    </div>

    <div class="flex flex-col bg-sn-white p-4 rounded-lg gap-2">
      <div class="flex mb-2">
        <div class="text-xl font-semibold"> {{ i18n.t('my_modules.reports.generated_title') }} </div>
      </div>
      <div v-for="report in reports" class="flex items-center justify-between border border-sn-light-grey rounded px-2">
        <div class="flex items-center gap-2">
          <i class="sn-icon sn-icon-file-pdf text-sn-grey"></i>
          <a class="file-preview-link file-name"
             :id="`modal_link${report.id}`"
             data-no-turbolink="true"
             :data-id="report.id"
             :data-gallery-view-id="myModuleId"
             :data-preview-url="report.preview">{{ report.name }}</a>
        </div>
        <div class="flex items-center gap-2">
          <div class="text-sn-grey">{{ i18n.t('my_modules.reports.cretated', { date: report.created_at }) }}</div>
          <button
            v-if="editable"
            class="btn btn-light icon-btn"
            data-render-tooltip="true"
            :title="i18n.t('general.delete')"
            @click.stop="deleteReport(report)"
          >
            <i class="sn-icon sn-icon-delete"></i>
          </button>
          <a
            class="btn btn-light icon-btn"
            target="_blank"
            :href="download_url(report.id)"
            data-render-tooltip="true"
            :title="i18n.t('general.download')"
          >
            <i class="sn-icon sn-icon-export"></i>
          </a>
        </div>
      </div>
      <div v-if="!reports || reports?.length == 0">
        {{ i18n.t('my_modules.reports.no_reports') }}
      </div>
    </div>
  </div>
  <DeleteModal
    :title="deleteTitle"
    :description="i18n.t('my_modules.reports.delete.description_html')"
    :confirmClass="'btn btn-danger'"
    :confirmText="i18n.t('general.delete')"
    ref="deleteModal"
  ></DeleteModal>
</template>

<script>
import axios from '../../packs/custom_axios.js';
import DeleteModal from '../shared/confirmation_modal.vue';
import {
  my_module_my_module_reports_path,
  my_module_my_module_report_path,
  generated_reports_my_module_my_module_reports_path,
  download_my_module_my_module_report_path
} from '../../routes.js'

export default {
  name: 'MyModuleReports',
  props: {
    myModuleId: {
      required: true
    },
    editable: {
      default: false
    }
  },
  components: {
    DeleteModal
  },
  data() {
    return {
      templates: [],
      reports: [],
      deleteTitle: ''
    }
  },
  created() {
    this.fetchTemplates();
    this.fetchGeneratedReports();
  },
  computed: {
    loadUrl() {
      return my_module_my_module_reports_path(this.myModuleId);
    },
    loadGeneratedReportUrl() {
      return generated_reports_my_module_my_module_reports_path(this.myModuleId);
    }
  },
  methods: {
    download_url(reportId) {
      return download_my_module_my_module_report_path(this.myModuleId, reportId);
    },
    fetchTemplates() {
      axios.get(this.loadUrl).then((response) => {
        this.templates = response.data.templates;
      });
    },
    fetchGeneratedReports() {
      axios.get(this.loadGeneratedReportUrl).then((response) => {
        this.reports = response.data.reports;
      });
    },
    async deleteReport(report) {
      this.deleteTitle = this.i18n.t('my_modules.reports.delete.title', { name: report.name })
      const ok = await this.$refs.deleteModal.show();

      if (ok) {
        axios.delete(my_module_my_module_report_path(this.myModuleId, report.id)).then((response) => {
          this.fetchGeneratedReports();
        }).catch((error) => {
          HelperModule.flashAlertMsg(this.i18n.t('general.error'), 'danger');
        });
      }
    },
    generateReport(templateId) {
      axios.post(my_module_my_module_reports_path(this.myModuleId), {
        report_template_id: templateId
      }).then((response) => {
        this.fetchGeneratedReports();
      }).catch((error) => {
        HelperModule.flashAlertMsg(this.i18n.t('general.error'), 'danger');
      });
    }
  }
};
</script>
