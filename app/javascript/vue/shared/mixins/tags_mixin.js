import axios from '../../../packs/custom_axios.js';
import {
  tags_path
} from '../../../routes.js';

export default {
  props: {
    subject: {
      type: Object,
      required: true
    },
  },
  computed: {
    canManage() {
      return this.subject.attributes.permissions.manage_tags;
    },
    canAssign() {
      return this.subject.attributes.permissions.assign_tags;
    },
    tagResourceUrl() {
      return this.subject.attributes.urls.tag_resource;
    },
    untagResourceUrl() {
      return this.subject.attributes.urls.untag_resource;
    },
    createTagUrl() {
      return this.subject.attributes.urls.tag_resource_with_new_tag;
    }
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
      searchQuery: ''
    };
  },
  methods: {
    loadAllTags() {
      axios.get(tags_path()).then((response) => {
        this.allTags = response.data.data;
      });
    },
    linkTag(tag) {
      if (this.tags.map(t => t.id).includes(tag.id)) {
        this.unlinkTag(tag);
        return;
      }

      if (this.linkingTag) {
        return;
      }

      this.linkingTag = true;

      axios.post(this.tagResourceUrl, {
        tag_id: tag.id,
      }).then((response) => {
        this.tags.push(response.data.tag);
        this.subject.attributes.tags = this.tags;
        this.linkingTag = false;
        this.searchQuery = '';
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
        tag_id: tag.id,
      }).then((response) => {
        this.tags = this.tags.filter(t => t.id !== tag.id);
        this.subject.attributes.tags = this.tags;
        this.linkingTag = false;
        this.searchQuery = '';
      }).catch(() => {
        this.linkingTag = false;
        HelperModule.flashAlertMsg(I18n.t('errors.general'), 'danger');
      });
    }
  }
};
