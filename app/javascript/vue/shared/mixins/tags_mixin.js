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
      return this.permissions.can_create || this.permissions.can_update || this.permissions.can_delete || false;
    },
    canCreate() {
      return this.permissions.can_create || false;
    },
    canUpdate() {
      return this.permissions.can_update || false;
    },
    canDelete() {
      return this.permissions.can_delete || false;
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
    this.loadAllTagsWithPermissions();
    this.tags = this.subject.attributes.tags || [];
  },
  data() {
    return {
      tags: [],
      allTags: [],
      permissions: {},
      linkingTag: false,
      searchQuery: ''
    };
  },
  methods: {
    loadAllTagsWithPermissions() {
      axios.get(tags_path({ mode: this.tagsLoadMode, subject_id: this.subject.id, subject_type: this.subject.type })).then((response) => {
        this.allTags = response.data.data;
        this.permissions = response.data.permissions;
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
        this.loadAllTagsWithPermissions();
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
        this.loadAllTagsWithPermissions();
      }).catch(() => {
        this.linkingTag = false;
        HelperModule.flashAlertMsg(I18n.t('errors.general'), 'danger');
      });
    }
  }
};
