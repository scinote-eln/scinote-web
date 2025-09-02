<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title truncate !block" >
            {{ i18n.t('tags.merge_modal.title') }}
          </h4>
        </div>
        <div class="modal-body">
          <p>{{ i18n.t('tags.merge_modal.description_html') }}</p>
          <div>
            <div class="sci-label mb-1">{{ i18n.t('tags.merge_modal.target_tag') }}</div>
            <SelectDropdown
              :optionsUrl="listUrl"
              :value="selectedTagId"
              :searchable="true"
              :placeholder="i18n.t('tags.merge_modal.target_tag_placeholder')"
              @change="selectedTagId = $event"
              :option-renderer="tagRenderer"
            ></SelectDropdown>
          </div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.close') }}</button>
          <button type="button" class="btn btn-danger" :disabled="!selectedTagId" @click="mergeTags">
            {{ i18n.t('tags.merge_modal.merge') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import SelectDropdown from '../../shared/select_dropdown.vue';
import modalMixin from '../../shared/modal_mixin';
import axios from '../../../packs/custom_axios.js';
import escapeHtml from '../../shared/escape_html.js';
import {
  merge_users_settings_team_tag_path,
} from '../../../routes.js';

export default {
  name: 'MergeTagsModal',
  props: {
    teamId: {
      required: true
    },
    listUrl: {
      type: String,
      required: true
    },
    mergeIds: {
      type: Array,
      required: true
    }
  },
  components: {
    SelectDropdown
  },
  mixins: [modalMixin, escapeHtml],
  data() {
    return {
      selectedTagId: null
    };
  },
  methods: {
    mergeTags() {
      axios.post(merge_users_settings_team_tag_path(this.selectedTagId, {team_id: this.teamId}), {
        merge_ids: this.mergeIds
      }).then(() => {
        HelperModule.flashAlertMsg(this.i18n.t('tags.merge_modal.merge_success'), 'success');
        this.$emit('close');
      }).catch((error) => {
        HelperModule.flashAlertMsg(this.i18n.t('tags.merge_modal.merge_error'), 'danger');
      });
    },
    tagRenderer(tag) {
      return `<div class="sci-tag text-white" style="background-color: ${escapeHtml(tag[2])};">${escapeHtml(tag[1])}</div>`;
    }
  }
};
</script>
