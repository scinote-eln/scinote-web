<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <form @submit.prevent="submit">
        <div class="modal-content">
          <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
              <i class="sn-icon sn-icon-close"></i>
            </button>
            <h4 class="modal-title truncate !block">
              {{ i18n.t('user_groups.show.add_members_modal.title') }}
            </h4>
          </div>
          <div class="modal-body">
            <div>
              <label class="sci-label">{{ i18n.t('user_groups.show.add_members_modal.select_members') }}</label>
              <SelectDropdown
                :optionsUrl="usersUrl"
                @change="changeUsers"
                :withCheckboxes="true"
                :option-renderer="usersRenderer"
                :label-renderer="usersRenderer"
                :multiple="true"
                :searchable="true"
                :placeholder="i18n.t('user_groups.show.add_members_modal.select_members_placeholder')"
              />
            </div>
          </div>
          <div class="modal-footer">
            <button
              type="button"
              class="btn btn-secondary"
              data-dismiss="modal"
            >
              {{ i18n.t('general.cancel') }}
            </button>
            <button
              class="btn btn-primary"
              type="submit"
              :disabled="submitting || users.length === 0"
            >
              {{ i18n.t('user_groups.show.add_members') }}
            </button>
          </div>
        </div>
      </form>
    </div>
  </div>
</template>

<script>

import SelectDropdown from '../../shared/select_dropdown.vue';
import axios from '../../../packs/custom_axios.js';
import modalMixin from '../../shared/modal_mixin';
import escapeHtml from '../../../shared/escape_html.js';

export default {
  name: 'AddMembersModal',
  props: {
    usersUrl: String,
    createUrl: String
  },
  mixins: [modalMixin, escapeHtml],
  components: {
    SelectDropdown,
  },
  data() {
    return {
      users: [],
      submitting: false
    };
  },
  methods: {
    changeUsers(selectedUsers) {
      this.users = selectedUsers;
    },
    async submit() {
      this.submitting = true;

      await axios.post(this.createUrl, {
        user_ids: this.users,
      }).then(() => {
        HelperModule.flashAlertMsg(this.i18n.t('user_groups.show.add_members_modal.success') , 'success');
        this.$emit('create');
      }).catch(() => {
        HelperModule.flashAlertMsg(this.i18n.t('user_groups.show.add_members_modal.error'), 'danger');
      });
      this.submitting = false;
    },
    usersRenderer(user) {
      return `<div class="flex items-center gap-2 truncate">
                <img class="w-6 h-6 rounded-full" src="${user[2].avatar}">
                <span title="${escapeHtml(user[1])}" class="truncate">${escapeHtml(user[1])}</span>
              </div>`;
    }
  }
};
</script>
