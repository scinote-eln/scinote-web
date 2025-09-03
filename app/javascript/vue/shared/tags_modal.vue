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

        </div>
        <div class="modal-footer">
          <button class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.close') }}</button>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
import modalMixin from '../../shared/modal_mixin';
import GeneralDropdown from '../../shared/general_dropdown.vue';
import TagsMixin from './mixins/tags_mixin.js';

export default {
  name: 'TagsModal',
  emits: ['close', 'tagsLoaded', 'tagDeleted'],
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
      tags: [],
      allTags: [],
      linkingTag: false,
    };
  },
  created() {
    this.loadAllTags();
    this.tags = this.subject.attributes.tags || [];
  },
  methods: {
  }
};
</script>
