<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <form @submit.prevent="submit">
        <div class="modal-content">
          <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
              <i class="sn-icon sn-icon-close"></i>
            </button>
            <h4 class="modal-title truncate !block" id="edit-project-modal-label" :title="my_module.name">
              {{ i18n.t('experiments.table.modal_move_modules.title') }}
            </h4>
          </div>
          <div class="modal-body">
            <p>{{ i18n.t('experiments.table.modal_move_modules.description') }}</p>
            <div class="mb-2">
              <label class="sci-label">{{ i18n.t('experiments.table.modal_move_modules.project') }}</label>
              <SelectDropdown
                :optionsUrl="projectsUrl"
                :searchable="true"
                :value="selectedProject"
                :placeholder="i18n.t('experiments.table.modal_move_modules.select_project')"
                @change="changeProject"
              />
            </div>
            <div class="mt-4">
              <label class="sci-label">{{ i18n.t('experiments.table.modal_move_modules.experiment') }}</label>
              <SelectDropdown
                :optionsUrl="experimentsUrl"
                :urlParams="{ project_id: selectedProject }"
                :disabled="!(selectedProject != null && selectedProject >= 0)"
                :searchable="true"
                :value="selectedExperiment"
                :placeholder="i18n.t('experiments.table.modal_move_modules.select_experiment')"
                @change="changeExperiment"
              />
            </div>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.cancel') }}</button>
            <button class="btn btn-primary" :disabled="submitting || !selectedExperiment" type="submit">
              {{ i18n.t('experiments.table.modal_move_modules.confirm') }}
            </button>
          </div>
        </div>
      </form>
    </div>
  </div>
</template>

<script>
/* global HelperModule */

import SelectDropdown from '../../shared/select_dropdown.vue';
import axios from '../../../packs/custom_axios.js';
import modalMixin from '../../shared/modal_mixin';
import {
  projects_to_move_projects_path,
  experiments_to_move_experiments_path
} from '../../../routes.js';

export default {
  name: 'MoveModal',
  props: {
    my_module: Object
  },
  mixins: [modalMixin],
  components: {
    SelectDropdown
  },
  data() {
    return {
      selectedProject: this.my_module.project_id,
      selectedExperiment: null,
      submitting: false,
    };
  },
  computed: {
    projectsUrl() {
      return projects_to_move_projects_path();
    },
    experimentsUrl() {
      return experiments_to_move_experiments_path();
    }
  },
  methods: {
    submit() {
      this.submitting = true;

      axios.post(this.my_module.movePath, {
        to_experiment_id: this.selectedExperiment
      }).then((response) => {
        this.$emit('move');
        this.submitting = false;
        HelperModule.flashAlertMsg(response.data.message, 'success');
      }).catch((error) => {
        this.submitting = false;
        HelperModule.flashAlertMsg(error.response.data.message, 'danger');
      });
    },
    changeProject(project) {
      this.selectedProject = project;
      this.selectedExperiment = null;
    },
    changeExperiment(experiment) {
      this.selectedExperiment = experiment;
    }
  }
};
</script>
