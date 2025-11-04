<template>
  <div>
    <GeneralDropdown ref="tagsDropdown" :canOpen="canAssign" @open="openSearch" @close="closeSearch">
      <template v-slot:field>
        <div class="w-full flex flex-wrap rounded gap-2 p-1 border border-solid"
             :class="{
                '!border-sn-science-blue cursor-pointer': opened,
                'hover:!border-sn-light-grey !border-transparent cursor-pointer': !opened && canAssign,
                '!border-transparent': !canAssign
             }">
          <template  v-if="tags.length > 0">
            <div v-for="tag in tags" :key="tag.id" class="sci-tag" :class="tagTextColor(tag.color)" :style="{ backgroundColor: tag.color }" >
              <div class="text-block" :title="tag.name">{{ tag.name }}</div>
              <i v-if="canAssign" @click.stop="unlinkTag(tag)" class="sn-icon sn-icon-close"></i>
            </div>
          </template>
          <div v-else-if="!opened && canAssign" class="sci-tag bg-sn-super-light-grey">
            {{ i18n.t('tags.tags_input.add_tag') }}
          </div>
          <input v-if="opened"
            @click.stop="handleInputClick"
            @keydown.delete.stop="handleInputDelete"
            @keydown.enter.stop="handleInputEnter"
            :placeholder="tags.length == 0 ? i18n.t('tags.tags_input.placeholder') : ''"
            type="text"
            ref="tagSearch"
            v-model="searchQuery"
            class="flex-grow outline-none leading-4 border-none bg-transparent p-1 placeholder:text-sn-grey" />
        </div>
      </template>
      <template v-slot:flyout>
        <div class="flex flex-col">
          <div class="max-h-[40vh] overflow-auto">
            <div v-if="validTagName && canCreate" @click="createTag" class="btn btn-light btn-black w-32">
              <i class="sn-icon sn-icon-new-task"></i>
              {{ i18n.t('tags.tags_input.create_tag') }}
            </div>
            <div v-for="tag in filteredTags" :key="tag.id" @click="linkTag(tag)" class="py-2 cursor-pointer hover:bg-sn-super-light-grey px-3 flex items-center gap-2" >
              <div class="sci-tag" :class="tagTextColor(tag.color)"  :style="{ backgroundColor: tag.color }" >
                <div class="text-block" :title="tag.name">{{ tag.name }}</div>
              </div>
            </div>
          </div>
          <span v-if="noTagsAvailable" class="text-sn-grey pl-3 py-2">{{ i18n.t('tags.tags_input.no_options_found') }}</span>
          <template v-if="canManage || (canAssign && !noTagsAvailable)">
            <hr class="my-0 w-full mb-1 border-t"  />
            <button class="btn btn-light btn-black w-32" @click="openTagsModal">
              <span class="sn-icon sn-icon-edit"></span>
              {{ i18n.t('tags.tags_input.edit_tags') }}
            </button>
          </template>
        </div>
      </template>
    </GeneralDropdown>
    <TagsModal :subject="subject" v-if="tagsModalOpened" @close="closeTagsModal" />
  </div>
</template>

<script>
import GeneralDropdown from './general_dropdown.vue';
import TagsMixin from './mixins/tags_mixin.js';
import TagsModal from './tags_modal.vue';
import axios from '../../packs/custom_axios.js';

export default {
  name: 'TagsInput',
  components: {
    GeneralDropdown,
    TagsModal
  },
  mixins: [TagsMixin],
  computed: {
    filteredTags() {
      if (this.searchQuery.trim() === '') {
        return this.allTags;
      }
      const lowerQuery = this.searchQuery.toLowerCase();
      return this.allTags.filter(tag => tag.name.toLowerCase().includes(lowerQuery));
    },
    validTagName() {
      return this.searchQuery.trim().length > GLOBAL_CONSTANTS.NAME_MIN_LENGTH &&
        !this.allTags.map(t => t.name.toLowerCase()).includes(this.searchQuery.toLowerCase());
    },
    noTagsAvailable() {
      return this.allTags.length === 0;
    }
  },
  data() {
    return {
      opened: false,
      tagsModalOpened: false,
      tagsLoadMode: 'unlinked'
    };
  },
  methods: {
    createTag() {
      if (this.linkingTag || this.searchQuery.trim() === '') {
        return;
      }

      this.linkingTag = true;

      axios.post(this.createTagUrl, {
        tag: {
          name: this.searchQuery.trim()
        }
      }).then((response) => {
        this.tags.push(response.data.tag);
        this.subject.attributes.tags = this.tags;
        this.loadAllTagsWithPermissions();
        this.linkingTag = false;
        this.searchQuery = '';
      }).catch((e) => {
        this.linkingTag = false;
        console.error(e);
        if (e.response?.data?.error) {
          HelperModule.flashAlertMsg(e.response.data.error, 'danger');
          return;
        }
        HelperModule.flashAlertMsg(I18n.t('errors.general'), 'danger');
      });
    },
    openSearch() {
      this.opened = true;
      this.$nextTick(() => {
        this.$refs.tagSearch.focus();
      });
    },
    closeSearch() {
      this.opened = false;
      this.searchQuery = '';
    },
    handleInputClick() {
    },
    handleInputEnter() {
      if (this.validTagName && this.canCreate) {
        this.createTag();
      } else if (this.filteredTags.length > 0 && this.canAssign) {
        this.linkTag(this.filteredTags[0]);
      }
    },
    handleInputDelete() {
      if (this.searchQuery.trim() === '' && this.tags.length > 0) {
        this.unlinkTag(this.tags[this.tags.length - 1]);
      }
    },
    tagTextColor(color) {
      return window.isColorBright(color) ? 'text-black' : 'text-white';
    },
    openTagsModal() {
      this.tagsModalOpened = true;
      this.$refs.tagsDropdown.isOpen = false;
    },
    closeTagsModal() {
      this.tagsModalOpened = false;
      this.$emit('reloadSubject');
    }
  }
}
</script>
