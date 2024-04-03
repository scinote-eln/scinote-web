<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <form @submit.prevent="submit">
        <div class="modal-content">
          <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
              <i class="sn-icon sn-icon-close"></i>
            </button>
            <h4 class="modal-title truncate !block" id="edit-project-modal-label">
              {{ i18n.t('projects.index.modal_new_project_folder.modal_title') }}
            </h4>
          </div>
          <div class="modal-body">
            <div class="mb-6">
              <label class="sci-label">{{ i18n.t('projects.index.modal_new_project_folder.name') }}</label>
              <div class="sci-input-container-v2" :class="{'error': error}" :data-error="error">
                <input type="text" v-model="name"
                       class="sci-input-field" autofocus="true" ref="input"
                       :placeholder="i18n.t('projects.index.modal_new_project.name_placeholder')" />
              </div>
            </div>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.cancel') }}</button>
            <button class="btn btn-primary" type="submit">
              {{ i18n.t('projects.index.modal_new_project.create') }}
            </button>
          </div>
        </div>
      </form>
    </div>
  </div>
</template>

<script>

import SelectDropdown from '../../shared/select_dropdown.vue';
import axios from '../../../packs/custom_axios.js';
import modalMixin from '../../shared/modal_mixin';

export default {
  name: 'NewProjectModal',
  props: {
    createFolderUrl: String,
    userRolesUrl: String,
    viewMode: String,
    currentFolderId: String,
  },
  mixins: [modalMixin],
  components: {
    SelectDropdown,
  },
  data() {
    return {
      name: '',
      error: null,
    };
  },
  methods: {
    submit() {
      axios.post(this.createFolderUrl, {
        project_folder: {
          name: this.name,
          parent_folder_id: this.currentFolderId,
          archived: (this.viewMode === 'archived'),
        },
      }).then(() => {
        this.error = null;
        this.$emit('create');
      }).catch((error) => {
        this.error = error.response.data.name;
      });
    },
    changeRole(role) {
      this.defaultRole = role;
    },
  },
};
</script>
