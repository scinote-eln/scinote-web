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
          <h4 class="modal-title">
            {{ i18n.t("repositories.modal_assign_items_to_task.title") }}
          </h4>
          <button
            type="button"
            class="close"
            data-dismiss="modal"
            aria-label="Close"
          >
            <span aria-hidden="true">&times;</span>
          </button>
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

            <SelectSearch
              :value="selectedProject"
              ref="projectsSelector"
              @change="changeProject"
              :options="projects"
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
              :searchPlaceholder="
                i18n.t(
                  'repositories.modal_assign_items_to_task.body.project_select.placeholder'
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

            <SelectSearch
              :value="selectedExperiment"
              :disabled="!selectedProject"
              ref="experimentsSelector"
              @change="changeExperiment"
              :options="experiments"
              :placeholder="experimentsSelectorPlaceholder"
              :no-options-placeholder="
                i18n.t(
                  'repositories.modal_assign_items_to_task.body.experiment_select.no_options_placeholder'
                )
              "
              :searchPlaceholder="
                i18n.t(
                  'repositories.modal_assign_items_to_task.body.experiment_select.placeholder'
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

            <SelectSearch
              :value="selectedTask"
              :disabled="!selectedExperiment"
              ref="tasksSelector"
              @change="changeTask"
              :options="tasks"
              :placeholder="tasksSelectorPlaceholder"
              :no-options-placeholder="
                i18n.t(
                  'repositories.modal_assign_items_to_task.body.task_select.no_options_placeholder'
                )
              "
              :searchPlaceholder="
                i18n.t(
                  'repositories.modal_assign_items_to_task.body.task_select.placeholder'
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
import SelectSearch from "../shared/select_search.vue";

export default {
  name: "AssignItemsToTaskModalContainer",
  props: {
    visibility: Boolean,
    urls: Object
  },
  data() {
    return {
      rowsToAssign: [],
      projects: [],
      experiments: [],
      tasks: [],
      selectedProject: null,
      selectedExperiment: null,
      selectedTask: null,
      showCallback: null
    };
  },
  components: {
    SelectSearch
  },
  created() {
    window.AssignItemsToTaskModalComponent = this;
  },
  mounted() {
    $(this.$refs.modal).on("shown.bs.modal", () => {
      $.get(this.projectURL, data => {
        if (Array.isArray(data)) {
          this.projects = data;
          return false;
        }
        this.projects = [];
      });
    });

    $(this.$refs.modal).on("hidden.bs.modal", () => {
      this.resetSelectors();
      this.$emit("close");
    });
  },
  beforeDestroy() {
    delete window.AssignItemsToTaskModalComponent;
  },
  computed: {
    experimentsSelectorPlaceholder() {
      if (this.selectedProject) {
        return this.i18n.t(
          "repositories.modal_assign_items_to_task.body.experiment_select.placeholder"
        );
      }
      return this.i18n.t(
        "repositories.modal_assign_items_to_task.body.experiment_select.disabled_placeholder"
      );
    },
    tasksSelectorPlaceholder() {
      if (this.selectedExperiment) {
        return this.i18n.t(
          "repositories.modal_assign_items_to_task.body.task_select.placeholder"
        );
      }
      return this.i18n.t(
        "repositories.modal_assign_items_to_task.body.task_select.disabled_placeholder"
      );
    },
    projectURL() {
      return `${this.urls.projects}`;
    },
    experimentURL() {
      return `${this.urls.experiments}?project_id=${this.selectedProject ||
        ""}`;
    },
    taskURL() {
      return `${this.urls.tasks}?experiment_id=${this.selectedExperiment ||
        ""}`;
    },
    assignURL() {
      return this.urls.assign.replace(":module_id", this.selectedTask);
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
      $(this.$refs.modal).modal("show");

      this.rowsToAssign = this.showCallback();
    },
    hideModal() {
      $(this.$refs.modal).modal("hide");
    },
    changeProject(value) {
      this.selectedProject = value;
      this.resetExperimentSelector();
      this.resetTaskSelector();

      $.get(this.experimentURL, data => {
        if (Array.isArray(data)) {
          this.experiments = data;
          return false;
        }
        this.experiments = [];
      });
    },
    changeExperiment(value) {
      this.selectedExperiment = value;
      this.resetTaskSelector();

      $.get(this.taskURL, data => {
        if (Array.isArray(data)) {
          this.tasks = data;
          return false;
        }
        this.tasks = [];
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
        type: "PATCH",
        dataType: "json",
        data: { rows_to_assign: this.rowsToAssign }
      }).done(({assigned_count}) => {
        const skipped_count = this.rowsToAssign.length - assigned_count;

        if (skipped_count) {
          HelperModule.flashAlertMsg(this.i18n.t('repositories.modal_assign_items_to_task.assign.flash_some_assignments_success', {assigned_count: assigned_count, skipped_count: skipped_count }), 'success');
        } else {
          HelperModule.flashAlertMsg(this.i18n.t('repositories.modal_assign_items_to_task.assign.flash_all_assignments_success', {count: assigned_count}), 'success');
        }
      }).fail(() => {
        HelperModule.flashAlertMsg(this.i18n.t('repositories.modal_assign_items_to_task.assign.flash_assignments_failure'), 'danger');
      }).always(() => {
        this.resetSelectors();
        this.deselectRows();
      });
    },
    setShowCallback(callback) {
      this.showCallback = callback;
    },
    deselectRows() {
      $('.repository-row-selector:checked').trigger('click');
    }
  }
};
</script>
