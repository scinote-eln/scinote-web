<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <form @submit.prevent="submit">
        <div class="modal-content" data-e2e="e2e-MD-projects-newProject">
          <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-label="Close" data-e2e="e2e-BT-projects-newProjectModal-close">
              <i class="sn-icon sn-icon-close"></i>
            </button>
            <h4 class="modal-title truncate !block" id="edit-project-modal-label" :title="project?.name" data-e2e="e2e-TX-projects-newProjectModal-title">
              {{ modalHeader }}
            </h4>
          </div>
          <div class="modal-body">
            <div class="mb-6">
              <label class="sci-label">{{ i18n.t("projects.index.modal_new_project.name") }}</label>
              <div class="sci-input-container-v2" :class="{'error': error}" :data-error="error">
                <input type="text" v-model="name" class="sci-input-field"
                       autofocus="true" ref="input"
                       :placeholder="i18n.t('projects.index.modal_new_project.name_placeholder')"
                       data-e2e="e2e-IF-projects-newProjectModal-name"
                />
              </div>
            </div>
            <div class="mb-6">
              <label class="sci-label">{{ i18n.t("projects.index.start_date") }}</label>
              <DateTimePicker
                @change="updateStartDate"
                :defaultValue="startDate"
                mode="date"
                :clearable="true"
                :placeholder="i18n.t('projects.index.add_start_date')"
                :dataE2e="'e2e-DP-projects-newProjectModal-start'"
              />
            </div>
            <div class="mb-6">
              <label class="sci-label">{{ i18n.t("projects.index.due_date") }}</label>
              <DateTimePicker
                @change="updateDueDate"
                :defaultValue="dueDate"
                mode="date"
                :clearable="true"
                :placeholder="i18n.t('projects.index.add_due_date')"
                :dataE2e="'e2e-DP-projects-newProjectsModal-due'"
              />
            </div>
            <div class="mb-6" data-e2e="e2e-IF-projects-newProjectModal-description">
              <TinymceEditor
                v-model="description"
                textareaId="descriptionModelInput"
                :placeholder="i18n.t('projects.index.add_description')"
              ></TinymceEditor>
            </div>
            <div class="flex gap-2 text-xs items-center">
              <div class="sci-checkbox-container">
                <input type="checkbox" class="sci-checkbox" v-model="visible" value="visible" data-e2e="e2e-CB-projects-newProjectModal-access"/>
                <span class="sci-checkbox-label"></span>
              </div>
              <span v-html="i18n.t('projects.index.modal_new_project.visibility_html')"></span>
            </div>
            <div class="mt-6" :class="{'hidden': !visible}">
              <label class="sci-label">{{ i18n.t("user_assignment.select_default_user_role") }}</label>
              <SelectDropdown
                :options="userRoles"
                :value="defaultRole"
                @change="changeRole"
                :e2eValue="'e2e-DD-projects-newProjectModal-defaultRole'"
              />
            </div>
          </div>
          <div class="modal-footer">
            <button
              type="button"
              class="btn btn-secondary"
              data-dismiss="modal"
              data-e2e="e2e-BT-projects-newProjectModal-cancel"
            >
              {{ i18n.t('general.cancel') }}
            </button>
            <button
              class="btn btn-primary"
              type="submit"
              :disabled="submitting || (visible && !defaultRole) || !validName"
              data-e2e="e2e-BT-projects-newProjectModal-create"
            >
              {{ submitButtonLabel }}
            </button>
          </div>
        </div>
      </form>
    </div>
  </div>
</template>

<script>

import SelectDropdown from '../../shared/select_dropdown.vue';
import DateTimePicker from '../../shared/date_time_picker.vue';
import TinymceEditor from '../../shared/tinymce_editor.vue';
import axios from '../../../packs/custom_axios.js';
import modalMixin from '../../shared/modal_mixin';

export default {
  name: 'ProjectFormModal',
  props: {
    project: Object,
    userRolesUrl: String,
    currentFolderId: String,
    createUrl: String
  },
  mixins: [modalMixin],
  components: {
    SelectDropdown,
    DateTimePicker,
    TinymceEditor
  },
  watch: {
    visible(newValue) {
      if (newValue) {
        [this.defaultRole] = this.userRoles.find((role) => role[1] === 'Viewer');
      } else {
        this.defaultRole = null;
      }
    }
  },
  computed: {
    validName() {
      return this.name.length >= GLOBAL_CONSTANTS.NAME_MIN_LENGTH;
    },
    modalHeader() {
      if (this.createUrl) {
        return this.i18n.t('projects.index.modal_new_project.modal_title');
      }

      return this.i18n.t('projects.index.modal_edit_project.modal_title', { project: this.project?.name });
    },
    submitButtonLabel() {
      if (this.createUrl) {
        return this.i18n.t('projects.index.modal_new_project.create');
      }

      return this.i18n.t('projects.index.modal_edit_project.submit');
    }
  },
  mounted() {
    this.fetchUserRoles();
  },
  data() {
    return {
      name: this.project?.name || '',
      visible: this.project ? !this.project.hidden : false,
      defaultRole: this.project?.default_public_user_role_id,
      error: null,
      userRoles: [],
      submitting: false,
      startDate: null,
      dueDate: null,
      description: this.project?.description || ''
    };
  },
  created() {
    if (this.project?.start_date_cell?.value) {
      this.startDate = new Date(this.project.start_date_cell?.value);
    }

    if (this.project?.due_date_cell?.value) {
      this.dueDate = new Date(this.project.due_date_cell?.value);
    }
  },
  methods: {
    async submit() {
      this.submitting = true;

      const projectData = {
        name: this.name,
        start_date: this.startDate,
        due_date: this.dueDate,
        description: this.description,
        visibility: (this.visible ? 'visible' : 'hidden'),
        default_public_user_role_id: this.defaultRole
      };

      if (this.createUrl) {
        projectData.project_folder_id = this.currentFolderId;
        this.createProject(projectData);
      } else {
        this.updateProject(projectData);
      }
    },
    async createProject(projectData) {
      await axios.post(this.createUrl, {
        project: projectData
      }).then(() => {
        this.error = null;
        this.$emit('create');
      }).catch((error) => {
        this.error = error.response.data.name;
      });
      this.submitting = false;
    },
    async updateProject(projectData) {
      await axios.put(this.project.urls.update, {
        project: projectData
      }).then(() => {
        this.error = null;
        this.$emit('update');
      }).catch((error) => {
        this.error = error.response.data.errors.name;
      });
      this.submitting = false;
    },
    changeRole(role) {
      this.defaultRole = role;
    },
    updateStartDate(startDate) {
      this.startDate = this.stripTime(startDate);
    },
    updateDueDate(dueDate) {
      this.dueDate = this.stripTime(dueDate);
    },
    fetchUserRoles() {
      if (this.userRolesUrl) {
        axios.get(this.userRolesUrl)
          .then((response) => {
            this.userRoles = response.data.data;
          });
      }
    },
    stripTime(date) {
      if (date) {
        return new Date(Date.UTC(
          date.getFullYear(),
          date.getMonth(),
          date.getDate(),
          0, 0, 0, 0
        ));
      }

      return date;
    }
  }
};
</script>
