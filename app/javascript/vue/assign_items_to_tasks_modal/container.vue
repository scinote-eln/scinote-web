<template>
  <div
    ref="modal"
    class="modal fade"
    id="assign-items-to-task-modal"
    tabindex="-1"
    role="dialog"
    aria-labelledby="assignItemsToTaskModalLabel"
  >
    <div class="modal-dialog" role="document">
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

          <div class="project-selector">
            <label>
              {{ i18n.t("repositories.modal_assign_items_to_task.body.project_select.label") }}
            </label>

            <SelectSearch
              ref="projectsSelector"
              @change="changeProject"
              :options="projects"
              :placeholder="i18n.t('repositories.modal_assign_items_to_task.body.project_select.placeholder')"
              :searchPlaceholder="i18n.t('repositories.modal_assign_items_to_task.body.project_select.placeholder')"
            />
          </div>

          <div class="experiment-selector">
            <label>
              {{ i18n.t("repositories.modal_assign_items_to_task.body.experiment_select.label") }}
            </label>

            <SelectSearch
              :disabled="!selectedProject"
              ref="experimentsSelector"
              @change="changeExperiment"
              :options="experiments"
              :placeholder="experimentsSelectorPlaceholder"
              :searchPlaceholder="i18n.t('repositories.modal_assign_items_to_task.body.experiment_select.placeholder')"
            />
          </div>

          <div class="task-selector">
            <label>
              {{ i18n.t("repositories.modal_assign_items_to_task.body.task_select.label") }}
            </label>

            <SelectSearch
              :disabled="!selectedExperiment"
              ref="tasksSelector"
              @change="changeTask"
              :options="tasks"
              :placeholder="i18n.t('repositories.modal_assign_items_to_task.body.task_select.disabled_placeholder')"
              :searchPlaceholder="i18n.t('repositories.modal_assign_items_to_task.body.task_select.placeholder')"
            />
          </div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-primary" data-dismiss="modal">
            {{
              i18n.t("repositories.modal_assign_items_to_task.assign")
            }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import SelectSearch from '../shared/select_search.vue'

export default {
  name: "AssignItemsToTaskModalContainer",
  props: {
    visibility: Boolean,
    urls: Object,
  },
  data() {
    return {
      projects: [
        [1, "project1"],
        [2, "project2"],
        [3, "project3"],
        [4, "project4"],
        [5, "project5"],
        [6, "project6"],
        [7, "project7"],
        [8, "project8"],
      ],
      experiments: [
        [1, "experiment1"],
        [2, "experiment2"],
        [3, "experiment3"],
        [4, "experiment4"],
        [5, "experiment5"],
        [6, "experiment6"],
        [7, "experiment7"],
        [8, "experiment8"],
      ],
      tasks: [
        [1, "task1"],
        [2, "task2"],
        [3, "task3"],
        [4, "task4"],
        [5, "task5"],
        [6, "task6"],
        [7, "task7"],
        [8, "task8"],
      ],
      selectedProject: null,
      selectedExperiment: null,
      selectedTask: null
    };
  },
  components: {
    SelectSearch
  },
  mounted() {
    $.get(this.urls.projects)
    $(this.$refs.modal).on('hidden.bs.modal', () => {
      this.$emit('close');
    });
  },
  computed: {
    experimentsSelectorPlaceholder() {
      if (this.selectedProject) {
        return this.i18n.t('repositories.modal_assign_items_to_task.body.experiment_select.placeholder');
      }
      return this.i18n.t('repositories.modal_assign_items_to_task.body.experiment_select.disabled_placeholder')
    },
    tasksSelectorPlaceholder() {
      if (this.selectedExperiment) {
        return this.i18n.t('repositories.modal_assign_items_to_task.body.task_select.placeholder');
      }
      return this.i18n.t('repositories.modal_assign_items_to_task.body.task_select.disabled_placeholder')
    }
  },
  watch: {
    visibility(newVal) {
      if (newVal) {
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
    hideModal(){
      $(this.$refs.modal).modal('hide');
    },
    changeProject(value) {
      const newProjectVal = value;
      this.selectedProject = null;
      this.selectedExperiment = null;
      this.selectedTask = null;

      setTimeout(() => {
        this.experiments = [
          [1, 'ex1'],
          [2, 'ex2'],
          [3, 'ex3'],
          [4, 'ex4']
        ];
        this.selectedProject = newProjectVal;
      }, 2000);

    },
    changeExperiment(value) {
      this.selectedExperiment = value;
    },
    changeTask(value) {
      this.selectedTask = value;
    }
  }
};
</script>
