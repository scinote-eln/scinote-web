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
              {{ this.title }}
            </h4>
          </div>
          <div class="modal-body">
            <div class="mb-4">{{ this.description }}</div>
            <div class="mb-4">
              <div class="sci-input-container-v2 left-icon">
                <input type="text"
                       v-model="query"
                       class="sci-input-field"
                       ref="input"
                       autofocus="true"
                       :placeholder="i18n.t('projects.index.modal_move_folder.find_folder')" />
                <i class="sn-icon sn-icon-search"></i>
              </div>
            </div>
            <div class="max-h-80 overflow-y-auto">
              <div class="p-2 flex items-center gap-2 cursor-pointer text-sn-blue hover:bg-sn-super-light-grey"
                    @click="selectFolder(null)"
                   :class="{'!bg-sn-super-light-blue': selectedFolderId == null}">
                <i class="sn-icon sn-icon-projects"></i>
                {{ i18n.t('projects.index.modal_move_folder.projects') }}
              </div>
              <MoveTree :objects="filteredFoldersTree" :value="selectedFolderId" @selectFolder="selectFolder" />
            </div>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.cancel') }}</button>
            <button class="btn btn-primary" type="submit">
              {{ i18n.t('projects.index.modal_move_folder.submit') }}
            </button>
          </div>
        </div>
      </form>
    </div>
  </div>
</template>

<script>
/* global HelperModule */

import axios from '../../../packs/custom_axios.js';
import modalMixin from '../../shared/modal_mixin';
import MoveTree from './move_tree.vue';

export default {
  name: 'NewProjectModal',
  props: {
    selectedObjects: Array,
    foldersTreeUrl: String,
    moveToUrl: String,
  },
  mixins: [modalMixin],
  data() {
    return {
      selectedFolderId: null,
      foldersTree: [],
      query: '',
    };
  },
  components: {
    MoveTree,
  },
  mounted() {
    axios.get(this.foldersTreeUrl).then((response) => {
      this.foldersTree = response.data;
    });
  },
  computed: {
    itemsName() {
      return this.i18n.t(`projects.index.modal_move_folder.items.${this.itemsType}`);
    },
    title() {
      return this.i18n.t('projects.index.modal_move_folder.title', { items: this.itemsName });
    },
    description() {
      return this.i18n.t('projects.index.modal_move_folder.description', { items: this.itemsName });
    },
    itemsType() {
      const allTypes = this.selectedObjects.map((obj) => obj.type);
      const uniqueTypes = [...new Set(allTypes)];
      if (uniqueTypes.length === 1) {
        return uniqueTypes[0];
      }
      return 'projects_and_folders';
    },
    filteredFoldersTree() {
      if (this.query === '') {
        return this.foldersTree;
      }
      return this.foldersTree.map((folder) => (
        {
          folder: folder.folder,
          children: folder.children.filter((child) => (
            child.folder.name.toLowerCase().includes(this.query.toLowerCase())
          )),
        }
      )).filter((folder) => (
        folder.folder.name.toLowerCase().includes(this.query.toLowerCase())
        || folder.children.length > 0
      ));
    },
  },
  methods: {
    selectFolder(folderId) {
      this.selectedFolderId = folderId;
    },
    submit() {
      axios.post(this.moveToUrl, {
        destination_folder_id: this.selectedFolderId || 'root_folder',
        movables: this.selectedObjects.map((obj) => (
          {
            id: obj.id,
            type: obj.type,
          }
        )),
      }).then((response) => {
        this.$emit('move');
        HelperModule.flashAlertMsg(response.data.message, 'success');
      }).catch((error) => {
        HelperModule.flashAlertMsg(error.response.data.message, 'danger');
      });
    },
  },
};
</script>
