<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header flex-wrap">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title truncate !block" id="generate-report-modal-label">
            {{ i18n.t('experiments.reports.generate_modal.title') }}
          </h4>
          <div class="basis-full">
            {{ i18n.t('experiments.reports.generate_modal.description') }}
          </div>
        </div>
        <div class="modal-body flex flex-col gap-4">
          <div  v-if="submitting" class="absolute inset-0 z-50 bg-white/90 flex items-center justify-center">
            <div class="px-6 py-4 flex items-center gap-4 border !border-transparent bg-sn-super-light-blue">
              <div class="sci-loader h-6 w-6 bg-contain"></div>
              <span>{{ i18n.t('experiments.reports.generate_modal.generating') }}</span>
            </div>
          </div >
          <div class="flex flex-col gap-1">
            <label class="sci-label">{{ i18n.t('experiments.reports.generate_modal.report_name') }}</label>
            <div class="sci-input-container-v2">
              <input type="text"
                v-model="reportName"
                class="sci-input-field"
                :placeholder="i18n.t('experiments.reports.generate_modal.report_name_placeholder')"
              />
            </div>
          </div>
          <div class="flex flex-col gap-4">
            <div class="text-base font-semibold">
              {{ i18n.t('experiments.reports.generate_modal.task_label') }}
            </div>
            <div v-if="loading" class="h-full flex items-center justify-center">
              <div class="sci-loader"></div>
            </div>
            <div v-else-if="tasks.length > 0" class="max-h-[400px] overflow-y-auto">
              <Draggable
                v-model="tasks"
                :ghostClass="'step-checklist-item-ghost'"
                :dragClass="'step-checklist-item-drag'"
                :chosenClass="'step-checklist-item-chosen'"
                handle=".widget-element-grip"
                item-key="id"
              >
                <template #item="{element}">
                  <div class="flex items-center gap-2 my-2 hover:bg-sn-super-light-grey group">
                    <div class="widget-element-grip cursor-pointer px-2">
                      <i class="sn-icon sn-icon-drag"></i>
                    </div>
                    <div class="flex items-center gap-2 p-3 bg-sn-super-light-grey w-full font-semibold">
                      <span class="sci-checkbox-container">
                        <input type="checkbox" class="sci-checkbox" v-model="element.checked" />
                        <span class="sci-checkbox-label"></span>
                      </span>
                      <div class="text-center flex items-center gap-2 w-full min-w-0">
                        <div class="truncate" data-render-tooltip="true" :title="element.name">
                          {{ element.name }}
                        </div>
                      </div>
                    </div>
                  </div>
                </template>
              </Draggable>
            </div>
            <div v-else>
              {{ i18n.t('experiments.reports.generate_modal.no_tasks') }}
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.close') }}</button>
          <button v-if="submitting" class="btn btn-primary" :disabled="true">
            <div class="sci-loader h-6 w-6 bg-contain"></div>
            {{ i18n.t('experiments.reports.generate_modal.generating_button') }}
          </button>
          <button
            v-else class="btn btn-primary"
            @click="generateReport"
            :disabled="!validName || !validTask"
            data-e2e="e2e-BT-experiment-generateAnaylticalReportModal-generate"
          > {{ i18n.t('experiments.reports.generate_button') }} </button>
        </div>
      </div>
    </div>

    <div class="flex items-center asset hidden">
      <a class="file-preview-link file-name text-base"
        ref="previewLinkRef"
        :data-preview-url="previewLink"></a>
    </div>
  </div>
</template>

<script>

import modalMixin from '../../shared/modal_mixin';
import axios from '../../../packs/custom_axios.js';
import Draggable from 'vuedraggable';
import ActionCableConsumer from '../../../channels/consumer';

import {
  my_modules_experiment_experiment_reports_path,
  experiment_experiment_reports_path
} from '../../../routes.js'

export default {
  name: 'GenerateReportModal',
  props: {
    experiment: Object,
  },
  mixins: [modalMixin],
  components: { Draggable },
  data() {
    return {
      loading: true,
      tasks: [],
      reportName: '',
      submitting: false,
      experimentReportGenerationsChannel: null,
      previewLink: null
    }
  },
  created() {
    this.experiment.generating = true;
    this.loadTasks();
  },
  beforeUnmount() {
    if (this.experimentReportGenerationsChannel) {
      ActionCableConsumer.subscriptions.remove(this.experimentReportGenerationsChannel);
    }
  },
  computed: {
    validName() {
      return this.reportName.length > 0;
    },
    validTask() {
      return this.tasks.some(task => task.checked);
    },
    createReportUrl() {
      return experiment_experiment_reports_path(this.experiment);
    }
  },
  methods: {
    loadTasks() {
      axios.get(my_modules_experiment_experiment_reports_path(this.experiment)).then((response) => {
        this.loading = false;
        this.tasks = response.data.tasks;
      });
    },
    generateReport() {
      this.submitting = true;
      const taskIds = this.tasks.filter(task => task.checked).map(task => task.id);
       axios.post(experiment_experiment_reports_path(this.experiment), {
        name: this.reportName,
        my_module_ids: taskIds
      }).then((response) => {
        this.$emit('create');
        if (!this.experimentReportGenerationsChannel) {
          this.experimentReportGenerationsChannel = ActionCableConsumer.subscriptions.create(
            { channel: 'ExperimentReportGenerationsChannel', experiment_id: this.experiment.id },
            {
              received: (data) => {
                if(data?.preview !== undefined) {
                  this.previewLink = data.preview;
                  this.$nextTick(() => {
                    this.$refs.previewLinkRef.click();
                    this.$emit('close');
                  });
                }
              }
            }
          );
        }
      });
    }
  }
};
</script>
