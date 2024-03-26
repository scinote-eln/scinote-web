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
              :value="selectedTask"
              :disabled="!selectedExperiment"
              :searchable="true"
              ref="tasksSelector"
              @change="changeTask"
              :options="tasks"
              :isLoading="tasksLoading"
              :placeholder="tasksSelectorPlaceholder"
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
            :disabled="!selectedTask"
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
import SelectDropdown from "../shared/select_dropdown.vue";

export default {
  name: 'AssignItemsToTaskModalContainer',
  props: {
    visibility: Boolean,
    urls: Object,
    rowsToAssign: Array
  },
  data() {
    return {
      projects: [],
      experiments: [],
      tasks: [],
      selectedProject: null,
      selectedExperiment: null,
      selectedTask: null,
      projectsLoading: null,
      experimentsLoading: null,
      tasksLoading: null
    };
  },
  components: {
    SelectDropdown
  },
  mounted() {
    $(this.$refs.modal).on('shown.bs.modal', () => {
      this.projectsLoading = true;

      $.get(this.projectURL, (data) => {
        if (Array.isArray(data)) {
          this.projects = data;
          return false;
        }
        this.projects = [];
      }).always(() => {
        this.projectsLoading = false;
      });
    });

    $(this.$refs.modal).on('hidden.bs.modal', () => {
      this.resetSelectors();
      this.$emit('close');
    });
  },
  beforeUnmount() {
    delete window.AssignItemsToTaskModalComponent;
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
      return `${this.urls.projects}`;
    },
    experimentURL() {
      return `${this.urls.experiments}?project_id=${this.selectedProject
        || ''}`;
    },
    taskURL() {
      return `${this.urls.tasks}?experiment_id=${this.selectedExperiment
        || ''}`;
    },
    assignURL() {
      return this.urls.assign.replace(':module_id', this.selectedTask);
    }
  },
  watch: {
    visibility() {
      if (this.visibility) {
        this.showModal();
      } else {
        this.hideModal();
      }
    }
  },
  methods: {
    showModal() {
      $(this.$refs.modal).modal('show');
    },
    hideModal() {
      $(this.$refs.modal).modal('hide');
    },
    changeProject(value) {
      this.selectedProject = value;
      this.resetExperimentSelector();
      this.resetTaskSelector();

      this.experimentsLoading = true;
      $.get(this.experimentURL, (data) => {
        if (Array.isArray(data)) {
          this.experiments = data;
          return false;
        }
        this.experiments = [];
      }).always(() => {
        this.experimentsLoading = false;
      });
    },
    changeExperiment(value) {
      this.selectedExperiment = value;
      this.resetTaskSelector();

      this.tasksLoading = true;
      $.get(this.taskURL, (data) => {
        if (Array.isArray(data)) {
          this.tasks = data;
          return false;
        }
        this.tasks = [];
      }).always(() => {
        this.tasksLoading = false;
      });
    },
    changeTask(value) {
      this.selectedTask = value;
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
      this.selectedTask = null;
    },
    resetSelectors() {
      this.resetTaskSelector();
      this.resetExperimentSelector();
      this.resetProjectSelector();
    },
    assign() {
      if (!this.selectedTask) return;

      $.ajax({
        url: this.assignURL,
        type: 'PATCH',
        dataType: 'json',
        data: { rows_to_assign: this.rowsToAssign }
      }).done(({ assigned_count }) => {
        const skipped_count = this.rowsToAssign.length - assigned_count;

        if (skipped_count) {
          HelperModule.flashAlertMsg(this.i18n.t('repositories.modal_assign_items_to_task.assign.flash_some_assignments_success', { assigned_count, skipped_count }), 'success');
        } else {
          HelperModule.flashAlertMsg(this.i18n.t('repositories.modal_assign_items_to_task.assign.flash_all_assignments_success', { count: assigned_count }), 'success');
        }
      }).fail(() => {
        HelperModule.flashAlertMsg(this.i18n.t('repositories.modal_assign_items_to_task.assign.flash_assignments_failure'), 'danger');
      }).always(() => {
        this.resetSelectors();
        this.reloadTable();
        window.repositoryItemSidebarComponent.reload();
      });
    },
    reloadTable() {
      $('.repository-row-selector:checked').trigger('click');
      $('.repository-table')
        .find('table')
        .dataTable()
        .api()
        .ajax
        .reload();
    }
  }
};
</script>
