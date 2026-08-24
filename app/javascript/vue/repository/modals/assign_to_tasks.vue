<template>
  <div
    ref="modal"
    class="modal fade"
    id="assign-items-to-task-modal"
    tabindex="-1"
    role="dialog"
    aria-labelledby="assignItemsToTaskModalLabel"
  >
    <div class="modal-dialog modal-sm" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button
            type="button"
            class="close"
            data-dismiss="modal"
            aria-label="Close"
          >
          <i class="sn-icon sn-icon-close"></i>
        </button>
        <h4 class="modal-title">
          {{ i18n.t("repositories.modal_assign_items_to_task.title") }}
        </h4>
        </div>
        <div class="modal-body">
          <div class="description">
            {{
              i18n.t("repositories.modal_assign_items_to_task.body.description")
            }}
          </div>

          <div class="project-selector level-selector">
            <label>
              {{
                i18n.t(
                  "repositories.modal_assign_items_to_task.body.project_select.label"
                )
              }}
            </label>

            <SelectDropdown
              :value="selectedProject"
              ref="projectsSelector"
              :searchable="true"
              @change="changeProject"
              :options="projects"
              :isLoading="projectsLoading"
              :placeholder="
                i18n.t(
                  'repositories.modal_assign_items_to_task.body.project_select.placeholder'
                )
              "
              :no-options-placeholder="
                i18n.t(
                  'repositories.modal_assign_items_to_task.body.project_select.no_options_placeholder'
                )
              "
            />
          </div>

          <div class="experiment-selector level-selector">
            <label>
              {{
                i18n.t(
                  "repositories.modal_assign_items_to_task.body.experiment_select.label"
                )
              }}
            </label>

            <SelectDropdown
              :value="selectedExperiment"
              :disabled="!selectedProject"
              :searchable="true"
              ref="experimentsSelector"
              @change="changeExperiment"
              :options="experiments"
              :isLoading="experimentsLoading"
              :placeholder="experimentsSelectorPlaceholder"
              :no-options-placeholder="
                i18n.t(
                  'repositories.modal_assign_items_to_task.body.experiment_select.no_options_placeholder'
                )
              "
            />
          </div>

          <div class="task-selector level-selector">
            <label>
              {{
                i18n.t(
                  "repositories.modal_assign_items_to_task.body.task_select.label"
                )
              }}
            </label>

            <SelectDropdown
              :value="selectedTasks"
              :disabled="!selectedExperiment"
              :searchable="true"
              ref="tasksSelector"
              @change="changeTask"
              :options="tasks"
              :isLoading="tasksLoading"
              :placeholder="tasksSelectorPlaceholder"
              :multiple="true"
              :withCheckboxes="true"
              :no-options-placeholder="
                i18n.t(
                  'repositories.modal_assign_items_to_task.body.task_select.no_options_placeholder'
                )
              "
            />
          </div>
        </div>
        <div class="modal-footer">
          <button
            type="button"
            class="btn btn-primary"
            data-dismiss="modal"
            :disabled="!selectedTasks.length"
            @click="assign"
          >
            {{ i18n.t("repositories.modal_assign_items_to_task.assign.text") }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
/* global HelperModule */
import SelectDropdown from "../../shared/select_dropdown.vue";
import axios from '../../../packs/custom_axios.js';
import modalMixin from '../../shared/modal_mixin';

import {
  assign_my_modules_path,
  inventory_assigning_project_filter_projects_path,
  inventory_assigning_experiment_filter_experiments_path,
  inventory_assigning_my_module_filter_my_modules_path
} from '../../../routes.js';

export default {
  name: 'AssignItemsToTaskModalContainer',
  props: {
    rowsToAssign: Array,
    repositoryId: Number
  },
  mixins: [modalMixin],
  data() {
    return {
      projects: [],
      experiments: [],
      tasks: [],
      selectedProject: null,
      selectedExperiment: null,
      selectedTasks: [],
      projectsLoading: null,
      experimentsLoading: null,
      tasksLoading: null
    };
  },
  components: {
    SelectDropdown
  },
  mounted() {
    this.projectsLoading = true;

    axios.get(this.projectURL).then((response) => {
      const data = response.data;
      if (Array.isArray(data)) {
        this.projects = data;
        return false;
      }
      this.projects = [];
    }).finally(() => {
      this.projectsLoading = false;
    });
  },
  computed: {
    experimentsSelectorPlaceholder() {
      if (this.selectedProject) {
        return this.i18n.t(
          'repositories.modal_assign_items_to_task.body.experiment_select.placeholder'
        );
      }
      return this.i18n.t(
        'repositories.modal_assign_items_to_task.body.experiment_select.disabled_placeholder'
      );
    },
    tasksSelectorPlaceholder() {
      if (this.selectedExperiment) {
        return this.i18n.t(
          'repositories.modal_assign_items_to_task.body.task_select.placeholder'
        );
      }
      return this.i18n.t(
        'repositories.modal_assign_items_to_task.body.task_select.disabled_placeholder'
      );
    },
    projectURL() {
      return inventory_assigning_project_filter_projects_path();
    },
    experimentURL() {
      return inventory_assigning_experiment_filter_experiments_path({
        project_id: this.selectedProject || ''
      });
    },
    taskURL() {
      return inventory_assigning_my_module_filter_my_modules_path({
        experiment_id: this.selectedExperiment || ''
      });
    }
  },
  methods: {
    changeProject(value) {
      this.selectedProject = value;
      this.resetExperimentSelector();
      this.resetTaskSelector();

      this.experimentsLoading = true;
      axios.get(this.experimentURL).then((response) => {
        const data = response.data;
        if (Array.isArray(data)) {
          this.experiments = data;
          return false;
        }
        this.experiments = [];
      }).finally(() => {
        this.experimentsLoading = false;
      });
    },
    changeExperiment(value) {
      this.selectedExperiment = value;
      this.resetTaskSelector();

      this.tasksLoading = true;
      axios.get(this.taskURL).then((response) => {
        const data = response.data;
        if (Array.isArray(data)) {
          this.tasks = data;
          return false;
        }
        this.tasks = [];
      }).finally(() => {
        this.tasksLoading = false;
      });
    },
    changeTask(value) {
      this.selectedTasks = value;
    },
    resetProjectSelector() {
      this.projects = [];
      this.selectedProject = null;
    },
    resetExperimentSelector() {
      this.experiments = [];
      this.selectedExperiment = null;
    },
    resetTaskSelector() {
      this.tasks = [];
      this.selectedTasks = [];
    },
    resetSelectors() {
      this.resetTaskSelector();
      this.resetExperimentSelector();
      this.resetProjectSelector();
    },
    assign() {
      if (!this.selectedTasks.length) return;

      axios.post(assign_my_modules_path(this.repositoryId), {
          rows_to_assign: this.rowsToAssign,
          my_module_ids: this.selectedTasks
      }).then(({ data }) => {
        const { assigned_count: assignedCount, skipped_count: skippedCount } = data;
        this.$emit('reloadTable');
        if (skippedCount) {
          HelperModule.flashAlertMsg(
            this.i18n.t(
              'repositories.modal_assign_items_to_task.assign.flash_some_assignments_success',
              { assigned_count: assignedCount, skipped_count: skippedCount }
            ),
            'success'
          );
        } else {
          HelperModule.flashAlertMsg(
            this.i18n.t(
              'repositories.modal_assign_items_to_task.assign.flash_all_assignments_success',
              { count: assignedCount }
            ),
            'success'
          );
        }
      }).catch(() => {
        HelperModule.flashAlertMsg(this.i18n.t('repositories.modal_assign_items_to_task.assign.flash_assignments_failure'), 'danger');
      }).finally(() => {
        this.resetSelectors();
        window.repositoryItemSidebarComponent.reload();

      });
    },
  }
};
</script>
