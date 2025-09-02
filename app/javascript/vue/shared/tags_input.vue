<template>
  <div>
    <GeneralDropdown @open="opened = true" @close="opened = false">
      <template v-slot:field>
        <div class="w-full flex flex-wrap rounded gap-2 p-1 border border-solid  cursor-pointer"
             :class="{
                '!border-sn-science-blue': opened,
                'hover:!border-sn-light-grey !border-transparent': !opened,
             }">
          <template  v-if="tags.length > 0">
            <div v-for="tag in tags" :key="tag[0]" class="sci-tag  text-white" :style="{ backgroundColor: tag[2] }" >
              {{ tag[1] }}
              <i @click.stop="unlinkTag(tag)" class="sn-icon sn-icon-close"></i>
            </div>
          </template>
          <div v-else class="sci-tag bg-sn-super-light-grey">
            {{ i18n.t('tags.tags_input.add_tag') }}
          </div>
        </div>
      </template>
      <template v-slot:flyout>
        <div class="flex flex-col">
          <div v-for="tag in allTags" :key="tag[0]" @click="linkTag(tag)" class="py-2 cursor-pointer hover:bg-sn-super-light-grey px-3 flex items-center gap-2" >
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
import axios from '../../packs/custom_axios.js';
import GeneralDropdown from './general_dropdown.vue';
import {
  list_users_settings_team_tags_path,
} from '../../routes.js';

export default {
  name: 'TagsInput',
  props: {
    subject: {
      type: Object,
      required: true
    },
  },
  components: {
    GeneralDropdown,
  },
  computed: {
    tagsUrl() {
      return list_users_settings_team_tags_path({team_id: this.subject.attributes.team_id});
    },
    tagResourceUrl() {
      return this.subject.attributes.urls.tag_resource;
    },
    untagResourceUrl() {
      return this.subject.attributes.urls.untag_resource;
    },
  },
  created() {
    this.loadAllTags();
    this.tags = this.subject.attributes.tags || [];
  },
  data() {
    return {
      tags: [],
      allTags: [],
      linkingTag: false,
      opened: false,
    };
  },
  methods: {
    loadAllTags() {
      axios.get(this.tagsUrl).then((response) => {
        this.allTags = response.data.data;
      });
    },
    linkTag(tag) {
      if (this.tags.map(t => t[0]).includes(tag[0])) {
        this.unlinkTag(tag);
        return;
      }

      if (this.linkingTag) {
        return;
      }

      this.linkingTag = true;

      axios.post(this.tagResourceUrl, {
        tag_id: tag[0],
      }).then((response) => {
        this.tags.push(response.data.tag);
        this.linkingTag = false;
      }).catch(() => {
        this.linkingTag = false;
        HelperModule.flashAlertMsg(I18n.t('errors.general'), 'danger');
      });
    },

    unlinkTag(tag) {
      if (this.linkingTag) {
        return;
      }

      this.linkingTag = true;

      axios.post(this.untagResourceUrl, {
        tag_id: tag[0],
      }).then((response) => {
        this.tags = this.tags.filter(t => t[0] !== tag[0]);
        this.linkingTag = false;
      }).catch(() => {
        this.linkingTag = false;
        HelperModule.flashAlertMsg(I18n.t('errors.general'), 'danger');
      });
    },

  }
}
</script>
