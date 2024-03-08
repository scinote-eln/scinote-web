<template>
  <div ref="modal" class="modal" id="create-new-task-modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document" v-if="showModal">
      <form @submit.prevent="createTask">
        <div class="modal-content">
          <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal"><i class="sn-icon sn-icon-close"></i></button>
            <h2 class="modal-title"> {{ i18n.t('dashboard.create_task_modal.title') }} </h2>
          </div>
          <div class="modal-body flex flex-col gap-6">
            <!-- Task -->
            <div class="flex flex-col gap-2">
              <label class="sci-label">{{ i18n.t('dashboard.create_task_modal.task.label') }}</label>
              <div  class="sci-input-container-v2"
                    :class="{'error': errors['my_module']}" :data-error="errors['my_module']">
                <input type="text" class="sci-input-field"
                       v-model="task"
                       ref="input" :placeholder="i18n.t('dashboard.create_task_modal.task.placeholder')">
              </div>
            </div>
            <!-- Project -->
            <div  class="flex flex-col gap-2">
              <label class="sci-label"> {{ i18n.t('dashboard.create_task_modal.project.label') }}</label>
              <div :class="{'error': errors['project']}">
                <SelectDropdown :value="projectId"
                  :error="errors['project']"
                  :optionsUrl="projectsUrl"
                  :placeholder="projectName || i18n.t('dashboard.create_task_modal.project.placeholder')"
                  :searchable="true"
                  :optionRenderer="dropdownOptionRenderer"
                  @query="projectName = $event"
                  @change="projectId = $event" />
                <div class="text-sn-delete-red text-xs" :class="{ visible: errors.project }">
                  {{ errors.project }}
                </div>
              </div>
            </div>
            <!-- Project Visibility -->
            <div v-show="projectId === 0" class="flex gap-2 text-xs">
              <div class="sci-checkbox-container">
                <input type="checkbox" v-model="visible" class="sci-checkbox" />
                <span class="sci-checkbox-label"></span>
              </div>
              <span class="sci-label">{{ i18n.t('dashboard.create_task_modal.project.visibility_label') }}</span>
            </div>
            <!-- New project user roles -->
            <div v-show="visible" class="flex flex-col gap-2">
              <label class="sci-label"> {{ i18n.t('dashboard.create_task_modal.user_role.label') }}</label>
              <div>
                <SelectDropdown :value="defaultRole"
                  :options="userRoles"
                  :placeholder="i18n.t('dashboard.create_task_modal.user_role.placeholder')"
                  @change="defaultRole = $event"
                />
              </div>
            </div>
            <!-- Experiment -->
            <div class="flex flex-col gap-2">
              <label class="sci-label"> {{ i18n.t('dashboard.create_task_modal.experiment.label') }}</label>
              <div :class="{'error': errors['experiment']}">
                <SelectDropdown :value="experimentId"
                  :disabled="!validProject"
                  :error="errors['experiment']"
                  :optionsUrl="experimentsUrlValue"
                  :placeholder="experimentName || i18n.t('dashboard.create_task_modal.experiment.placeholder')"
                  :searchable="true"
                  :optionRenderer="dropdownOptionRenderer"
                  @query="experimentName = $event"
                  @change="experimentId = $event" />
                <div class="text-sn-delete-red text-xs" :class="{ visible: errors.experiment }">
                  {{ errors.experiment }}
                </div>
              </div>
            </div>
          </div>
          <div class="modal-footer">
            <button type="button"
              class="btn btn-secondary"
              data-dismiss="modal">
              {{ i18n. t('dashboard.create_task_modal.cancel') }}
            </button>
            <button type="submit"
                    class="create-task-button btn btn-primary"
                    :disabled="disableSave">
              {{ i18n. t('dashboard.create_task_modal.create') }}
            </button>
          </div>
        </div>
      </form>
    </div>
  </div>
</template>

<script>
/* global I18n */

import SelectDropdown from '../shared/select_dropdown.vue';
import axios from '../../packs/custom_axios';

export default {
  name: 'CreateNewtaskModal',
  components: {
    SelectDropdown
  },
  watch: {
    visible(newValue) {
      if (newValue) {
        [this.defaultRole] = this.userRoles.find((role) => role[1] === 'Viewer');
      } else {
        this.defaultRole = '';
      }
    },
    task() {
      this.$nextTick(() => {
        if (this.validTask) delete this.errors.my_module;
      });
    },
    projectName() {
      this.$nextTick(() => {
        if (this.projectName.trim().length > 1) delete this.errors.project;
      });
    },
    experimentName() {
      this.$nextTick(() => {
        if (this.experimentName.trim().length > 1) delete this.errors.experiment;
      });
    },
    projectId() {
      this.$nextTick(() => {
        this.experimentId = null;
        this.experimentName = '';
        delete this.errors.project;
      });
    },
    experimentId() {
      this.$nextTick(() => {
        delete this.errors.experiment;
      });
    }
  },
  computed: {
    disableSave() {
      return this.hasErrors
        || !this.validProject
        || !this.validExperiment
        || this.isSaving;
    },
    experimentsUrlValue() {
      if (this.validProject) return `${this.experimentsUrl}?project[id]=${this.projectId}`;

      return '';
    },
    validProject() {
      return this.projectId || this.projectId === 0;
    },
    validExperiment() {
      return this.experimentId || this.experimentId === 0;
    },
    validTask() {
      return this.task.trim().length > 1;
    },
    hasErrors() {
      return Object.keys(this.errors).length > 0;
    }
  },
  mounted() {
    $(this.$refs.modal)
      .on('show.bs.modal', () => {
        this.showModal = true;
        this.fetchUserRoles();
        this.$nextTick(() => {
          this.$refs.input?.focus();
        });
      })
      .on('hidden.bs.modal', () => { this.close(); });
  },
  data() {
    return {
      task: '',
      projectId: null,
      projectName: '',
      experimentId: null,
      experimentName: '',
      visible: false,
      errors: {},
      userRoles: [],
      defaultRole: '',
      showModal: false,
      isSaving: false
    };
  },
  props: {
    projectsUrl: { type: String, default: '' },
    experimentsUrl: { type: String, default: '' },
    userRolesUrl: { type: String, default: '' },
    createTaskUrl: { type: String, default: '' }
  },
  methods: {
    fetchUserRoles() {
      if (this.userRolesUrl) {
        axios.get(this.userRolesUrl)
          .then((response) => {
            this.userRoles = response.data.data;
          });
      }
    },
    validateInput() {
      if (!this.projectId && this.projectName.trim().length < 2) {
        this.errors.project = I18n.t('dashboard.create_task_modal.project.name_too_short_error');
      }
      if (!this.experimentId && this.experimentName.trim().length < 2) {
        this.errors.experiment = I18n.t('dashboard.create_task_modal.experiment.name_too_short_error');
      }
      if (!this.validTask) {
        this.errors.my_module = I18n.t('dashboard.create_task_modal.task.name_too_short_error');
      }
    },
    async createTask() {
      this.errors = {};
      this.validateInput();
      if (this.hasErrors) return;

      this.isSaving = true;
      await axios.post(this.createTaskUrl, {
        my_module: { name: this.task },
        project: {
          id: this.projectId,
          name: this.projectName,
          visibility: this.visible ? 1 : 0,
          default_public_user_role_id: this.defaultRole
        },
        experiment: { id: this.experimentId, name: this.experimentName }
      }).then((response) => {
        $(this.$refs.modal).modal('hide');
        window.location.replace(response.data.my_module_path);
      }).catch((error) => {
        this.errors.my_module = error.response.data.errors.my_module?.name?.join(',');
        this.errors.experiment = error.response.data.errors.experiment?.name?.join(',');
        this.errors.project = error.response.data.errors.project?.name?.join(',');
      });
      this.isSaving = false;
    },
    dropdownOptionRenderer(option) {
      if (option[0] === 0) {
        return `<div class="flex items-center" title="${option[1]}">
            <i class="sn-icon sn-icon-new-task"></i>
            <span class="truncate">${option[1]}</span>
          </div>`;
      }

      return `<span class="truncate">${option[1]}</span>`;
    },
    close() {
      this.task = '';
      this.projectId = null;
      this.projectName = '';
      this.experimentId = null;
      this.experimentName = '';
      this.errors = {};
      this.userRoles = [];
      this.visible = false;
      this.defaultRole = '';
      this.showModal = false;
    }
  }
};
</script>
