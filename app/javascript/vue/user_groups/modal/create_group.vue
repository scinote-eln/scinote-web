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
              {{ i18n.t('user_groups.index.create_modal.title') }}
            </h4>
          </div>
          <div class="modal-body">
            <p class="mb-4">
              {{ i18n.t('user_groups.index.create_modal.description') }}
            </p>
            <div class="mb-6">
              <label class="sci-label">{{ i18n.t('user_groups.index.create_modal.name') }}</label>
              <div class="sci-input-container-v2">
                <input type="text" v-model="name" class="sci-input-field"
                       autofocus="true" ref="input"
                       :placeholder="i18n.t('user_groups.index.create_modal.name_placeholder')"
                />
              </div>
            </div>
            <div class="mt-6">
              <label class="sci-label">{{ i18n.t('user_groups.index.create_modal.select_members') }}</label>
              <SelectDropdown
                :optionsUrl="usersUrl"
                @change="changeUsers"
                :withCheckboxes="true"
                :option-renderer="usersRenderer"
                :label-renderer="usersRenderer"
                :searchable="true"
                :multiple="true"
                :placeholder="i18n.t('user_groups.index.create_modal.select_members_placeholder')"
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
              :disabled="submitting || !validName"
            >
              {{ i18n.t('user_groups.index.create_modal.create_button') }}
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

export default {
  name: 'ProjectFormModal',
  props: {
    usersUrl: String,
    createUrl: String
  },
  mixins: [modalMixin],
  components: {
    SelectDropdown,
  },
  computed: {
    validName() {
      return this.name.length >= GLOBAL_CONSTANTS.NAME_MIN_LENGTH;
    }
  },
  data() {
    return {
      name: '',
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

      const userGroupData = {
        name: this.name,
        user_group_memberships_attributes: this.users.map((user) => ({
          user_id: user
        }))
      };

      await axios.post(this.createUrl, {
        user_group: userGroupData
      }).then((data) => {
        HelperModule.flashAlertMsg(data.data.message, 'success');
        this.$emit('create');
      }).catch((data) => {
        console.log(data);
        HelperModule.flashAlertMsg(data.response.data.error, 'danger');
      });
      this.submitting = false;
    },
    usersRenderer(user) {
      return `<div class="flex items-center gap-2 truncate">
                <img class="w-6 h-6 rounded-full" src="${user[2].avatar}">
                <span title="${user[1]}" class="truncate">${user[1]}</span>
              </div>`;
    }
  }
};
</script>
