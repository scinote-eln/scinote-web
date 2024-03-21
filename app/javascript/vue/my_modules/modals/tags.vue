<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 v-if="canManage" class="modal-title truncate !block">
            {{ i18n.t("experiments.canvas.modal_manage_tags.head_title") }}
          </h4>
          <h4 v-else class="modal-title truncate !block">
            {{ i18n.t("experiments.canvas.modal_manage_tags.head_title_read") }}
          </h4>
        </div>
        <div class="modal-body">
          <div v-if="canManage" class="mb-4">
            {{ i18n.t("experiments.canvas.modal_manage_tags.explanatory_text") }}
          </div>
          <div class="mb-4">
            <h5>{{ i18n.t("experiments.canvas.modal_manage_tags.project_tags", { project: this.projectName }) }}</h5>
          </div>
          <div class="max-h-80 overflow-y-auto" v-click-outside="finishEditMode">
            <template v-for="tag in allTags" :key="tag.id">
              <div
                  class="flex items-center gap-3 px-3 py-2.5 group"
                  :class="{
                    '!bg-sn-super-light-blue': tag.editing,
                    'hover:bg-sn-super-light-grey': canManage
                  }"
              >
                <div class="sci-checkbox-container">
                  <input type="checkbox"
                         :disabled="!canManage"
                         class="sci-checkbox"
                         :checked="tag.assigned" @change="toggleTag(tag)">
                  <label class="sci-checkbox-label"></label>
                </div>
                <div v-if="!tag.editing" @click="startEditMode(tag)"
                     class="h-6 px-1.5 flex items-center max-w-80 truncate text-sn-white rounded"
                     :class="{
                       'cursor-pointer': canManage
                     }"
                     :style="{ backgroundColor: tag.attributes.color }">
                  {{ tag.attributes.name }}
                </div>
                <template v-else>
                  <GeneralDropdown>
                    <template v-slot:field>
                      <div class="h-6 w-6 rounded relative flex items-center justify-center text-sn-white" :style="{ backgroundColor: tag.attributes.color }">
                        a
                      </div>
                    </template>
                    <template v-slot:flyout>
                      <div class="grid grid-cols-4 gap-1">
                        <div v-for="color in tagsColors" :key="color"
                            class="h-6 w-6 rounded relative flex items-center justify-center text-sn-white cursor-pointer"
                            @click.stop="updateTagColor(color, tag)"
                            :style="{ backgroundColor: color }">
                          <i v-if="color == tag.attributes.color" class="sn-icon sn-icon-check"></i>
                          <span v-else>a</span>
                        </div>
                      </div>
                    </template>
                  </GeneralDropdown>
                  <input type="text" :value="tag.attributes.name" class="border-0 grow focus:outline-none bg-transparent" @change="updateTagName($event.target.value, tag)"/>
                  <i @click.stop="finishEditMode($event, tag)" class="sn-icon sn-icon-check cursor-pointer ml-auto"></i>
                </template>
                <i  v-if="canManage" @click.stop="deleteTag(tag)"
                   class="tw-hidden sn-icon sn-icon-delete cursor-pointer group-hover:block"
                   :class="{
                     'ml-auto': !tag.editing,
                     '!block': tag.editing
                   }"
                ></i>
              </div>
            </template>
          </div>
          <template v-if="canManage">
            <div class="mb-4 mt-4">
              {{ i18n.t('experiments.canvas.modal_manage_tags.create_new') }}
            </div>
            <div class="flex gap-2">
              <GeneralDropdown>
                <template v-slot:field>
                  <div
                    class="h-6 w-6 border border-solid border-transparent rounded relative flex items-center justify-center text-sn-white"
                    :style="{ backgroundColor: newTag.color }"
                    :class="{'!border-sn-grey !text-sn-grey': !newTag.color}"
                  >
                    a
                  </div>
                </template>
                <template v-slot:flyout>
                  <div class="grid grid-cols-4 gap-1">
                    <div v-for="color in tagsColors" :key="color"
                        class="h-6 w-6 rounded relative flex items-center justify-center text-sn-white cursor-pointer"
                        @click.stop="newTag.color = color"
                        :style="{ backgroundColor: color }">
                      <i v-if="color == newTag.color" class="sn-icon sn-icon-check"></i>
                      <span v-else>a</span>
                    </div>
                  </div>
                </template>
              </GeneralDropdown>
              <input type="text" v-model="newTag.name"
                     :placeholder="i18n.t('experiments.canvas.modal_manage_tags.new_tag_name')"
                     class="border-0 focus:outline-none bg-transparent" />
              <i v-if="validNewTag" @click.stop="createTag" class="sn-icon sn-icon-check cursor-pointer ml-auto"></i>
              <i @click.stop="newTag = { name: null, color: null }"
                   class="tw-hidden sn-icon sn-icon-delete cursor-pointer "
                   :class="{
                     'ml-auto': !validNewTag,
                     '!block': newTag.name || newTag.color
                   }"
                ></i>
            </div>
          </template>
        </div>
        <div class="modal-footer">
          <button class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.close') }}</button>
        </div>
      </div>
    </div>
  </div>
  <ConfirmationModal
    :title="i18n.t('experiments.canvas.modal_manage_tags.delete_tag')"
    :description="i18n.t('experiments.canvas.modal_manage_tags.delete_tag_confirmation')"
    confirmClass="btn btn-danger"
    :confirmText="i18n.t('general.delete')"
    ref="deleteTagModal"
  ></ConfirmationModal>
</template>
<script>
import { vOnClickOutside } from '@vueuse/components';
import axios from '../../../packs/custom_axios.js';
import modalMixin from '../../shared/modal_mixin';
import InlineEdit from '../../shared/inline_edit.vue';
import GeneralDropdown from '../../shared/general_dropdown.vue';
import ConfirmationModal from '../../shared/confirmation_modal.vue';

export default {
  name: 'TagsModal',
  emits: ['close', 'tagsLoaded'],
  props: {
    params: {
      required: true
    },
    tagsColors: {
      required: true
    },
    projectTagsUrl: {
      required: true
    },
    projectName: {
      required: true
    }
  },
  directives: {
    'click-outside': vOnClickOutside
  },
  components: {
    InlineEdit,
    GeneralDropdown,
    ConfirmationModal
  },
  mixins: [modalMixin],
  data() {
    return {
      allTags: [],
      assignedTags: [],
      newTag: {
        name: null,
        color: null
      },
      loadingTags: false,
      tagToUpdate: null,
      query: ''
    };
  },
  computed: {
    validNewTag() {
      return this.newTag.name && this.newTag.color;
    },
    canManage() {
      return this.params.permissions.manage_tags;
    }
  },
  created() {
    this.loadAlltags();
  },
  methods: {
    startEditMode(tag) {
      if (!this.canManage) return;

      this.finishEditMode();

      tag.editing = true;
      this.tagToUpdate = tag;
      this.$nextTick(() => {
        this.$refs.modal.querySelector('input').focus();
      });
    },
    finishEditMode(e, tag = null) {
      if (e && e.target.closest('.sn-dropdown')) return;

      const tagToFinish = tag || this.allTags.find((t) => t.editing);

      if (tagToFinish) {
        tagToFinish.editing = false;
        this.updateTag(this.tagToUpdate);
      }
    },
    loadAlltags() {
      this.loadingTags = true;
      axios.get(this.projectTagsUrl).then((response) => {
        this.allTags = response.data.data;

        this.loadAssignedTags();
      });
    },
    loadAssignedTags() {
      axios.get(this.params.urls.assigned_tags).then((response) => {
        this.assignedTags = response.data.data;
        this.allTags.forEach((tag) => {
          const assignedTag = this.assignedTags.find((at) => at.attributes.tag_id === parseInt(tag.id, 10));
          if (assignedTag) {
            tag.assigned = true;
            tag.attributes.urls.unassign = assignedTag.attributes.urls.update;
          } else {
            tag.assigned = false;
          }
        });
        this.$emit('tagsLoaded', this.allTags);
        this.loadingTags = false;
      });
    },
    toggleTag(tag) {
      if (tag.assigned) {
        this.unassignTag(tag);
      } else {
        this.assignTag(tag);
      }
    },
    unassignTag(tag) {
      axios.delete(tag.attributes.urls.unassign).then(() => {
        this.loadAssignedTags();
      });
    },
    assignTag(tag) {
      axios.post(this.params.urls.assign_tags, {
        my_module_tag: {
          tag_id: tag.id
        }
      }).then(() => {
        this.loadAssignedTags();
      });
    },
    updateTagName(value) {
      this.tagToUpdate.attributes.name = value;
    },
    updateTagColor(color) {
      this.tagToUpdate.attributes.color = color;
    },
    updateTag(tag) {
      axios.put(tag.attributes.urls.update, {
        tag: {
          name: tag.attributes.name,
          color: tag.attributes.color
        },
        my_module_id: this.params.id
      });
    },
    createTag() {
      axios.post(this.projectTagsUrl, {
        tag: this.newTag,
        my_module_id: this.params.id
      }).then(() => {
        this.newTag = { name: null, color: null };
        this.loadAlltags();
      });
    },
    async deleteTag(tag) {
      const ok = await this.$refs.deleteTagModal.show();
      if (ok) {
        axios.delete(tag.attributes.urls.update, {
          data: {
            my_module_id: this.params.id
          }
        }).then(() => {
          this.loadAlltags();
          document.body.style.overflow = 'hidden';
        });
      } else {
        document.body.style.overflow = 'hidden';
      }
    }
  }
};
</script>
