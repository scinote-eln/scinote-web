<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title truncate !block" id="edit-project-modal-label">
            {{ i18n.t('experiments.reports.reports_modal.title') }}
          </h4>
        </div>
        <div class="modal-body">
          <div v-if="loading" class="h-full flex items-center justify-center">
            <div class="sci-loader"></div>
          </div>
          <div v-else class="flex flex-col gap-2">
            <div v-for="report in reports" class="flex items-center justify-between border border-sn-light-grey rounded p-2">
              <div class="flex flex-col gap-1">
                <div class="flex items-center asset">
                  <a class="file-preview-link file-name text-base"
                    :id="`modal_link${report.id}`"
                    data-no-turbolink="true"
                    :data-id="report.id"
                    :data-gallery-view-id="experiment.id"
                    :data-preview-url="report.preview">{{ report.name }}</a>
                </div>
                <div class="text-sn-grey flex flex-row gap-4">
                  <div>{{ i18n.t('experiments.reports.reports_modal.date', { date: report.created_at }) }}</div>
                  <div>{{ i18n.t('experiments.reports.reports_modal.created_by', { created_by: report.created_by }) }}</div>
                  <div>{{ i18n.t('experiments.reports.reports_modal.file_size', { size: report.file_size }) }}</div>
                </div>
              </div>
              <div class="flex items-center gap-2">
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
          </div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.close') }}</button>
          <button class="btn btn-primary" @click=""> {{  i18n.t('experiments.reports.generate_button') }} </button>
        </div>
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

import modalMixin from '../../shared/modal_mixin';
import axios from '../../../packs/custom_axios.js';
import DeleteModal from '../../shared/confirmation_modal.vue';

import {
  download_experiment_experiment_report_path,
  experiment_experiment_report_path
} from '../../../routes.js'

export default {
  name: 'ReportsModal',
  props: {
    experiment: Object,
  },
  mixins: [modalMixin],
  components: {
    DeleteModal
  },
  data() {
    return {
      loading: true,
      reports: [],
      deleteTitle: '',
    }
  },
  created() {
   this.loadReports();
  },
  computed: {
    editable() {
      return this.experiment.permissions.manage;
    }
  },
  methods: {
    loadReports() {
      this.loading = false;
      axios.get(this.experiment.urls.reports).then((response) => {
        this.loading = false;
        this.reports = response.data.reports;
      });
    },
    async deleteReport(report) {
      this.deleteTitle = this.i18n.t('my_modules.reports.delete.title', { name: report.name })
      const ok = await this.$refs.deleteModal.show();

      if (ok) {
        axios.delete(experiment_experiment_report_path(this.experiment.id, report.id)).then((response) => {
          this.loadReports();
        }).catch((error) => {
          HelperModule.flashAlertMsg(this.i18n.t('general.error'), 'danger');
        });
      }
    },
     download_url(reportId) {
      return download_experiment_experiment_report_path(this.experiment.id, reportId);
    },
  }
};
</script>
