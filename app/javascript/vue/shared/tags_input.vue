<template>
  <div>
    <GeneralDropdown :canOpen="canAssign" @open="openSearch" @close="closeSearch">
      <template v-slot:field>
        <div class="w-full flex flex-wrap rounded gap-2 p-1 border border-solid"
             :class="{
                '!border-sn-science-blue cursor-pointer': opened,
                'hover:!border-sn-light-grey !border-transparent cursor-pointer': !opened && canAssign,
                '!border-transparent': !canAssign
             }">
          <template  v-if="tags.length > 0">
            <div v-for="tag in tags" :key="tag[0]" class="sci-tag  text-white" :style="{ backgroundColor: tag[2] }" >
              {{ tag[1] }}
              <i v-if="canAssign" @click.stop="unlinkTag(tag)" class="sn-icon sn-icon-close"></i>
            </div>
          </template>
          <div v-else-if="!opened" class="sci-tag bg-sn-super-light-grey">
            {{ i18n.t('tags.tags_input.add_tag') }}
          </div>
          <input v-if="opened" @click.stop="handleInputClick" @keydown.enter.stop="handleInputEnter" type="text" ref="tagSearch" v-model="searchQuery"  class="flex-grow outline-none border-none bg-transparent p-1" />
        </div>
      </template>
      <template v-slot:flyout>
        <div class="flex flex-col">
          <div v-if="validTagName && canManage" @click="createTag" class="py-2 cursor-pointer hover:bg-sn-super-light-grey px-3 flex items-center gap-2">
            <i class="sn-icon sn-icon-new-task"></i>
            {{ i18n.t('tags.tags_input.create_tag') }}
          </div>
          <div v-for="tag in filteredTags" :key="tag[0]" @click="linkTag(tag)" class="py-2 cursor-pointer hover:bg-sn-super-light-grey px-3 flex items-center gap-2" >
            <div class="sci-checkbox-container pointer-events-none" >
              <input type="checkbox" :checked="tags.map(t => t[0]).includes(tag[0])" class="sci-checkbox" />
              <span class="sci-checkbox-label"></span>
            </div>
            <div class="sci-tag text-white" :style="{ backgroundColor: tag[2] }" >
              {{ tag[1] }}
            </div>
          </div>
          <hr class="my-0 border-t w-full mb-1">
          <button class="btn btn-light btn-black w-32">
            <span class="sn-icon sn-icon-edit"></span>
            {{ i18n.t('tags.tags_input.edit_tags') }}
          </button>
        </div>
      </template>
    </GeneralDropdown>
  </div>
</template>

<script>
import GeneralDropdown from './general_dropdown.vue';
import TagsMixin from './mixins/tags_mixin.js';

export default {
  name: 'TagsInput',
  components: {
    GeneralDropdown,
  },
  mixins: [TagsMixin],
  computed: {
    filteredTags() {
      if (this.searchQuery.trim() === '') {
        return this.allTags;
      }
      const lowerQuery = this.searchQuery.toLowerCase();
      return filter(this.allTags, tag => tag[1].toLowerCase().includes(lowerQuery));
    },
    validTagName() {
      return this.searchQuery.trim().length > GLOBAL_CONSTANTS.NAME_MIN_LENGTH &&
        !this.allTags.map(t => t[1].toLowerCase()).includes(this.searchQuery.toLowerCase());
    }
  },
  data() {
    return {
      opened: false,
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
        this.loadAllTags();
        this.linkingTag = false;
        this.searchQuery = '';
      }).catch(() => {
        this.linkingTag = false;
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
      if (this.validTagName && this.canManage) {
        this.createTag();
      } else if (this.filteredTags.length > 0 && this.canAssign) {
        this.linkTag(this.filteredTags[0]);
      }
    }
  }
}
</script>
