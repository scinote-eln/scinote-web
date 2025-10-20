<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title truncate !block">
            {{ i18n.t('tags.manage_modal.title') }}
          </h4>
        </div>
        <div class="modal-body">
          <p>
            {{ i18n.t('tags.manage_modal.description') }}
          </p>
          <div class="flex flex-col gap-2">
            <div ref="tagsContainer" class="grow overflow-auto max-h-[50vh]">
              <div v-for="tag in allTags" :key="tag.id"
                   class="rounded py-2 cursor-pointer hover:bg-sn-super-light-grey px-3 flex items-center gap-2"
                   :class="{'!bg-sn-super-light-blue': tagInEdit == tag.id }">
                <div v-if="canAssign" @click="linkTag(tag)" class="h-4">
                  <div class="sci-checkbox-container pointer-events-none" >
                    <input type="checkbox" :checked="tags.find(t => t.id === tag.id)" class="sci-checkbox" />
                    <span class="sci-checkbox-label"></span>
                  </div>
                </div>
                <GeneralDropdown :canOpen="canUpdate" >
                  <template v-slot:field>
                    <div
                      class="h-6 w-6 border border-solid border-transparent rounded relative flex items-center justify-center text-sn-white"
                      :style="{ backgroundColor: tag.color }"
                    >
                      a
                    </div>
                  </template>
                  <template v-slot:flyout>
                    <div class="grid grid-cols-4 gap-1">
                      <div v-for="color in colors" :key="color"
                          class="h-6 w-6 rounded relative flex items-center justify-center text-sn-white cursor-pointer"
                          @click.stop="changeColor(tag, color)"
                          :style="{ backgroundColor: color }">
                        <i v-if="color == tag.color" class="sn-icon sn-icon-check"></i>
                        <span v-else>a</span>
                      </div>
                    </div>
                  </template>
                </GeneralDropdown>
                <template v-if="canUpdate">
                  <span v-if="tagInEdit != tag.id" @click="startTagEditing(tag.id)" class="truncate grow cursor-pointer pl-1" :title="tag.name">{{ tag.name }}</span>
                  <input v-else type="text" :value="tag.name" @change="changeName(tag, $event.target.value)"
                    :class="{'pointer-events-none': !canUpdate }"
                    :ref="`tagInput${tag.id}`"
                    @blur="tagInEdit = null"
                    class=" text-sm grow outline-none leading-4 border-none bg-transparent p-1" />
                </template>
                <div v-else class="truncate max-w-[300px] overflow-hidden" :title="tag.name">
                  {{ tag.name }}
                </div>
                <i v-if="canDelete && newTagsCreated.includes(tag.id)" @click="deleteTag(tag)" class="ml-auto sn-icon sn-icon-delete"></i>
              </div>
            </div>
            <div>
              <div class="btn btn-light btn-black" v-if="canCreate && !addingNewTag" @click="startAddingNewTag">
                <i class="sn-icon sn-icon-new-task"></i>
                {{ i18n.t('tags.manage_modal.create_tag') }}
              </div>
            </div>
            <div v-if="addingNewTag" class="flex items-center gap-2 bg-sn-super-light-blue py-2 px-3 rounded">
              <div class="sci-checkbox-container pointer-events-none" >
                <input type="checkbox" class="sci-checkbox" />
                <span class="sci-checkbox-label"></span>
              </div>
              <div
                class="h-6 w-6 border border-solid border-transparent rounded relative flex items-center justify-center text-sn-white"
                :style="{ backgroundColor: newTag.color }"
              >
                a
              </div>
              <input type="text" ref="newTagInput" @blur="createTag"  v-model="newTag.name" :placeholder="i18n.t('tags.manage_modal.type_tag_name')" class="text-sm flex-grow outline-none leading-4 border-none bg-transparent p-1" />
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <a :href="tagsManagmentUrl" v-if="canDelete" class="btn btn-light mr-auto">
            {{ i18n.t('tags.manage_modal.manage_tags') }}
          </a>
          <button class="btn btn-primary" data-dismiss="modal">{{ i18n.t('general.done') }}</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import modalMixin from './modal_mixin';
import TagsMixin from './mixins/tags_mixin.js';
import GeneralDropdown from './general_dropdown.vue';
import axios from '../../packs/custom_axios.js';
import {
  colors_tags_path,
  team_tag_path,
  team_tags_path,
  users_settings_team_tags_path
} from '../../routes.js';


export default {
  name: 'TagsModal',
  mixins: [modalMixin, TagsMixin],
  components: {
    GeneralDropdown
  },
  data() {
    return {
      colors: [],
      teamId: null,
      addingNewTag: false,
      tagInEdit: null,
      newTag: {
        id: null,
        name: '',
        color: '#000000'
      },
      newTagsCreated: [],
      tagsLoadMode: 'all'
    };
  },
  created() {
    this.fetchColors();
    this.teamId = document.querySelector('body').dataset.currentTeamId;
  },
  computed: {
    validNewTag() {
      return this.newTag.name.trim() !== '' &&
             !this.allTags.find(t =>
               t.name.toLowerCase() === this.newTag.name.trim().toLowerCase() &&
               t.color === this.newTag.color
             );
    },
    tagsManagmentUrl() {
      return users_settings_team_tags_path({ team_id: this.teamId });
    }
  },
  methods: {
    startTagEditing(tagId) {
      this.tagInEdit = tagId;
      this.$nextTick(() => {
        this.$refs[`tagInput${tagId}`][0].focus();
      });
    },
    startAddingNewTag() {
      this.addingNewTag = true;
      this.newTag.name = '';
      this.newTag.color = this.colors[Math.floor(Math.random() * this.colors.length)];
      this.$nextTick(() => {
        this.$refs.newTagInput.focus();
      });
    },
    fetchColors() {
      axios.get(colors_tags_path())
        .then((response) => {
          this.colors = response.data.colors;
        });
    },
    changeColor(tag, color) {
      axios.patch(team_tag_path(tag.id, { team_id: this.teamId }), {
        tag: {
          color: color
        }
      }).then(() => {
        this.allTags.find(t => t.id === tag.id).color = color;
      }).catch(() => {
        HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
      });
    },
    changeName(tag, newName) {
      axios.patch(team_tag_path(tag.id, { team_id: this.teamId }), {
        tag: {
          name: newName
        }
      }).then(() => {
        this.allTags.find(t => t.id === tag.id).name = newName;
      }).catch((e) => {
        if (e.response?.data?.errors) {
          HelperModule.flashAlertMsg(e.response.data.errors, 'danger');
          return;
        }
        HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
      });
    },
    createTag() {
      if (!this.validNewTag) {
        this.addingNewTag = false;
        return;
      }
      axios.post(team_tags_path({ team_id: this.teamId }), {
        tag: {
          name: this.newTag.name,
          color: this.newTag.color
        }
      }).then((response) => {
        const tag = response.data.data;
        this.allTags.push({
          id: parseInt(tag.id, 10),
          name: tag.attributes.name,
          color: tag.attributes.color
        });
        this.newTagsCreated.push(parseInt(tag.id, 10));
        this.addingNewTag = false;
        this.$nextTick(() => {
          this.$refs.tagsContainer.scrollTop = this.$refs.tagsContainer.scrollHeight;
        });
      }).catch((e) => {
        if (e.response?.data?.errors) {
          HelperModule.flashAlertMsg(e.response.data.errors, 'danger');
          return;
        }
        HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
      });
    },
    deleteTag(tag) {
      if (!this.newTagsCreated.includes(tag.id)) {
        return;
      }
      axios.delete(team_tag_path(tag.id, { team_id: this.teamId }))
        .then(() => {
          this.allTags = this.allTags.filter(t => t.id !== tag.id);
          this.tags = this.tags.filter(t => t.id !== tag.id);
          this.subject.attributes.tags = this.tags;
        }).catch(() => {
          HelperModule.flashAlertMsg(this.i18n.t('errors.general'), 'danger');
        });
    }
  }
};
</script>
