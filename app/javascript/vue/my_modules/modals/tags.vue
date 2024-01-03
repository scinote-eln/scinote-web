<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title truncate !block" id="edit-project-modal-label">
            {{ i18n.t("experiments.canvas.modal_manage_tags.head_title") }}
          </h4>
        </div>
        <div class="modal-body">
          <div class="mb-4">
            {{ i18n.t("experiments.canvas.modal_manage_tags.explanatory_text") }}
          </div>
          <div class="max-h-80 overflow-y-auto">
            <div v-if="this.params.permissions.manage_tags" v-for="tag in tagsList" :key="tag.id"
                 class="flex items-center gap-2 px-3 py-2.5 hover:bg-sn-super-light-grey group">
              <GeneralDropdown>
                <template v-slot:field>
                  <div class="h-8 w-8 rounded relative" :style="{ backgroundColor: tag.attributes.color }">
                    <div class="absolute top-1 left-1 rounded-full w-1 h-1 bg-white"></div>
                  </div>
                </template>
                <template v-slot:flyout>
                  <div class="grid grid-cols-4 gap-1">
                    <div v-for="color in tagsColors" :key="color"
                         class="h-8 w-8 cursor-pointer rounded relative flex items-center justify-center"
                         @click="updateTagColor(color, tag)"
                         :style="{ backgroundColor: color }">
                      <div class="absolute top-1 left-1 rounded-full w-1 h-1 bg-white"></div>
                      <i v-if="color == tag.attributes.color" class="sn-icon sn-icon-check text-white"></i>
                    </div>
                  </div>
                </template>
              </GeneralDropdown>
              <div class="flex-grow truncate">
                <InlineEdit
                  :value="tag.attributes.name"
                  :characterLimit="255"
                  attributeName='Tag name'
                  :allowBlank="false"
                  :singleLine="true"
                  @update="(value) => updateTagName(value, tag)"
                />
              </div>
              <i class="tw-hidden group-hover:block sn-icon sn-icon-close cursor-pointer" @click="unassignTag(tag)"></i>
            </div>
            <div v-else v-for="tag in tagsList" :key="tag.id" class="flex items-center gap-2 px-3 py-2.5">
              <div class="h-8 w-8 rounded relative" :style="{ backgroundColor: tag.attributes.color }">
                <div class="absolute top-1 left-1 rounded-full w-1 h-1 bg-white"></div>
              </div>
              <div class="flex-grow truncate">
                {{ tag.attributes.name }}
              </div>
            </div>
          </div>
          <div v-if="this.params.permissions.manage_tags"
               class="text-sn-grey flex items-center gap-2 px-3 cursor-pointer
                       py-2.5 hover:bg-sn-super-light-grey"
               @click="createTag()"
          >
            <div class="h-8 w-8 rounded relative border-sn-grey border-solid">
              <div class="absolute top-1 left-1 rounded-full w-1 h-1 bg-white border-sn-grey  border-solid"></div>
            </div>
            <div>{{ i18n.t('experiments.canvas.modal_manage_tags.create_new') }}</div>
          </div>
        </div>
        <div class="modal-footer">
          <div v-if="(tagsToAssign.length > 0 || !this.loadingTags)
                     && this.params.permissions.manage_tags" class="mr-auto">
            <GeneralDropdown ref="assignDropdown">
              <template v-slot:field>
                <button class="btn btn-primary">{{ i18n.t('general.assign') }}</button>
              </template>
              <template v-slot:flyout>
                <div class="max-h-80 overflow-y-auto">
                  <div v-for="tag in tagsToAssign" :key="tag.id"
                      @click="assignTag(tag)"
                      class="px-3 py-2.5 hover:bg-sn-super-light-grey cursor-pointer flex items-center gap-2">
                      <div class="h-6 w-6 rounded relative" :style="{ backgroundColor: tag.attributes.color }">
                        <div class="absolute top-1 left-1 rounded-full w-1 h-1 bg-white"></div>
                      </div>
                    <div class="min-w-[10rem] truncate">{{ tag.attributes.name }}</div>
                    <i @click.stop="deleteTag(tag)" class="sn-icon sn-icon-delete cursor-pointer ml-auto"></i>
                  </div>
                </div>
              </template>
            </GeneralDropdown>
          </div>
          <button class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.cancel') }}</button>
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

import axios from '../../../packs/custom_axios.js';
import modalMixin from '../../shared/modal_mixin';
import InlineEdit from '../../shared/inline_edit.vue';
import GeneralDropdown from '../../shared/general_dropdown.vue';
import ConfirmationModal from '../../shared/confirmation_modal.vue';

export default {
  name: 'TagsModal',
  emits: ['close'],
  props: {
    params: {
      required: true
    },
    tagsColors: {
      required: true
    },
    projectTagsUrl: {
      required: true
    }
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
      loadingTags: false,
      query: ''
    };
  },
  computed: {
    tagsList() {
      return this.assignedTags.map((tag) => {
        const tagObject = this.allTags.find((t) => parseInt(t.id, 10) === tag.attributes.tag_id);
        const modifiedTag = tag;
        modifiedTag.attributes = {
          ...tag.attributes,
          name: tagObject.attributes.name,
          color: tagObject.attributes.color
        };
        return modifiedTag;
      });
    },
    tagsToAssign() {
      return this.allTags.filter((tag) => (
        !this.assignedTags.find((t) => t.attributes.tag_id === parseInt(tag.id, 10))
        && tag.attributes.name.toLowerCase().includes(this.query.toLowerCase())
      ));
    }
  },
  created() {
    this.loadAlltags();
  },
  methods: {
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
        this.loadingTags = true;
      });
    },
    unassignTag(tag) {
      axios.delete(tag.attributes.urls.update).then(() => {
        this.loadAssignedTags();
      });
    },
    assignTag(tag) {
      this.$refs.assignDropdown.closeMenu();
      axios.post(this.params.urls.assign_tags, {
        my_module_tag: {
          tag_id: tag.id
        }
      }).then(() => {
        this.loadAssignedTags();
      });
    },
    updateTagName(value, tag) {
      const tagToUpdate = this.allTags.find((t) => parseInt(t.id, 10) === tag.attributes.tag_id);
      tagToUpdate.attributes.name = value;
      this.updateTag(tagToUpdate);
    },
    updateTagColor(color, tag) {
      const tagToUpdate = this.allTags.find((t) => parseInt(t.id, 10) === tag.attributes.tag_id);
      tagToUpdate.attributes.color = color;
      this.updateTag(tagToUpdate);
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
      const randmonColor = this.tagsColors[Math.floor(Math.random() * this.tagsColors.length)];
      axios.post(this.projectTagsUrl, {
        tag: {
          name: this.i18n.t('tags.create.new_name'),
          color: randmonColor
        },
        my_module_id: this.params.id
      }).then(() => {
        this.loadAlltags();
      });
    },
    async deleteTag(tag) {
      this.$refs.assignDropdown.closeMenu();
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
