<template>
  <div>
    <div class="mb-4">
      <label class="sci-label">{{ i18n.t("dashboard.create_task_modal.task_name") }}</label>
      <div class="sci-input-container-v2" :class="{
        'error': !validTaskName && taskName.length > 0
      }" >
        <input type="text" ref="taskName" class="sci-input" v-model="taskName" :placeholder="i18n.t('dashboard.create_task_modal.task_name_placeholder')" />
      </div>
      <span v-if="!validTaskName && taskName.length > 0" class="sci-error-text">
        {{ i18n.t("dashboard.create_task_modal.task_name_error", { length: minLength }) }}
      </span>
    </div>
    <div class="mb-2">
      <label class="sci-label">{{ i18n.t("dashboard.create_task_modal.project") }}</label>
      <SelectDropdown
        :optionsUrl="projectsUrl"
        :searchable="true"
        :value="selectedProject"
        :optionRenderer="newProjectRenderer"
        :placeholder="i18n.t('dashboard.create_task_modal.project_placeholder')"
        @change="changeProject"
      />
    </div>
    <div v-if="selectedProject == 0">
      <div class="flex gap-2 text-xs items-center">
        <div class="sci-checkbox-container">
          <input type="checkbox" class="sci-checkbox" v-model="publicProject" value="visible"/>
          <span class="sci-checkbox-label"></span>
        </div>
        <span v-html="i18n.t('projects.index.modal_new_project.visibility_html')"></span>
      </div>
      <div class="mt-4" :class="{'hidden': !publicProject}">
        <label class="sci-label">{{ i18n.t("dashboard.create_task_modal.user_role") }}</label>
        <SelectDropdown
          :options="userRoles"
          :value="defaultRole"
          @change="changeRole"
          :placeholder="i18n.t('dashboard.create_task_modal.user_role_placeholder')"
        />
      </div>
    </div>
    <div class="mt-4">
      <label class="sci-label">{{ i18n.t("dashboard.create_task_modal.experiment") }}</label>
      <SelectDropdown
        :optionsUrl="experimentsUrl"
        :urlParams="{ project: {
          id: selectedProject,
          name: newProjectName
        }}"
        :disabled="!(selectedProject != null && selectedProject >= 0)"
        :searchable="true"
        :value="selectedExperiment"
        :placeholder="i18n.t('dashboard.create_task_modal.experiment_placeholder')"
        :optionRenderer="newExperimentRenderer"
        @change="changeExperiment"
      />
    </div>
    <hr class="my-6">
    <div class="flex items-center justify-end gap-4">
      <button class="btn btn-light" @click="closeModal">
        {{ i18n.t("dashboard.create_task_modal.cancel") }}
      </button>
      <button class="btn btn-primary" @click="createMyModule" :disabled="!validTaskName || !validExperiment || !validProject || creatingTask">
        {{ i18n.t("dashboard.create_task_modal.create") }}
      </button>
    </div>
  </div>
</template>

<script>
/* global GLOBAL_CONSTANTS */

import SelectDropdown from '../shared/select_dropdown.vue';
import axios from '../../packs/custom_axios.js';

export default {
  name: 'DashboardNewTask',
  components: {
    SelectDropdown
  },
  computed: {
    validTaskName() {
      return this.taskName.length >= this.minLength;
    },
    validExperiment() {
      return this.selectedExperiment != null || this.newExperimentName.length > this.minLength;
    },
    validProject() {
      return this.selectedProject != null || this.newProjectName.length > this.minLength;
    },
    minLength() {
      return GLOBAL_CONSTANTS.NAME_MIN_LENGTH;
    }
  },
  created() {
    this.fetchUserRoles();
    $('#create-task-modal').on('hidden.bs.modal', () => {
      this.$emit('close');
    });

    $('#create-task-modal').on('shown.bs.modal', this.focusInput);
  },
  unmounted() {
    $('#create-task-modal').off('shown.bs.modal', this.focusInput);
  },
  props: {
    projectsUrl: {
      type: String,
      required: true
    },
    experimentsUrl: {
      type: String,
      required: true
    },
    rolesUrl: {
      type: String,
      required: true
    },
    createUrl: {
      type: String,
      required: true
    }
  },
  data() {
    return {
      projects: [],
      selectedProject: null,
      newProjectName: '',
      experiments: [],
      selectedExperiment: null,
      newExperimentName: '',
      userRoles: [],
      taskName: '',
      publicProject: false,
      defaultRole: null,
      creatingTask: false
    };
  },
  methods: {
    createMyModule() {
      if (this.creatingTask) return;

      this.creatingTask = true;

      axios.post(this.createUrl, {
        my_module: {
          name: this.taskName
        },
        experiment: {
          id: this.selectedExperiment,
          name: this.newExperimentName
        },
        project: {
          id: this.selectedProject,
          name: this.newProjectName,
          visibility: (this.publicProject ? 'visible' : 'hidden'),
          default_public_user_role_id: this.defaultRole
        }
      })
        .then((response) => {
          this.creatingTask = false;
          window.location.href = response.data.my_module_path;
        });
    },
    changeRole(value) {
      this.defaultRole = value;
    },
    changeProject(value, label) {
      this.selectedProject = value;
      this.newProjectName = label;
    },
    changeExperiment(value, label) {
      this.selectedExperiment = value;
      this.newExperimentName = label;
    },
    newProjectRenderer(option) {
      if (option[0] > 0) {
        return option[1];
      }
      return `
        <div class="flex items-center gap-2 truncate">
          <span class="sn-icon sn-icon-new-task"></span>
          <span class="truncate">${this.i18n.t('dashboard.create_task_modal.new_project', { name: option[1] })}</span
        </div>
      `;
    },
    newExperimentRenderer(option) {
      if (option[0] > 0) {
        return option[1];
      }
      return `
        <div class="flex items-center gap-2 truncate">
          <span class="sn-icon sn-icon-new-task"></span>
          <span class="truncate">${this.i18n.t('dashboard.create_task_modal.new_experiment', { name: option[1] })}</span
        </div>
      `;
    },
    closeModal() {
      $('#create-task-modal').modal('hide');
      this.taskName = '';
      this.selectedProject = null;
      this.newProjectName = '';
      this.selectedExperiment = null;
      this.newExperimentName = '';
    },
    fetchUserRoles() {
      axios.get(this.rolesUrl)
        .then((response) => {
          this.userRoles = response.data.data;
        });
    },
    focusInput() {
      this.$refs.taskName.focus();
    }
  }
};
</script>
