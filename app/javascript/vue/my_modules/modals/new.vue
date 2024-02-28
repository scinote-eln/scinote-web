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
              {{ i18n.t('experiments.canvas.new_my_module_modal.title') }}
            </h4>
          </div>
          <div class="modal-body">
            <label class="sci-label">{{ i18n.t('experiments.canvas.new_my_module_modal.name') }}</label>
            <div class="sci-input-container-v2 mb-4">
              <input type="text" class="sci-input-field"
                     v-model="name"
                     autofocus ref="input"
                    :placeholder="i18n.t('experiments.canvas.new_my_module_modal.name_placeholder')">
            </div>

            <label class="sci-label">
              {{ i18n.t('experiments.canvas.new_my_module_modal.due_date') }}
            </label>
            <DateTimePicker
              @change="setDueDate"
              mode="datetime"
              class="mb-4"
              size="mb"
              :placeholder="i18n.t('experiments.canvas.new_my_module_modal.due_date_placeholder')"
              :clearable="true"/>

              <label class="sci-label">
                {{ i18n.t('experiments.canvas.new_my_module_modal.assigned_tags_label') }}
              </label>
              <SelectDropdown
                class="mb-4"
                @change="setTags"
                :options="formattedTags"
                :option-renderer="tagsRenderer"
                :label-renderer="tagsRenderer"
                :multiple="true"
                :searchable="true"
                :placeholder="i18n.t('experiments.canvas.new_my_module_modal.assigned_tags_placeholder')"
                :tagsView="true" ></SelectDropdown>

                <label class="sci-label">
                  {{ i18n.t('experiments.canvas.new_my_module_modal.assigned_users') }}
                </label>
                <SelectDropdown
                  @change="setUsers"
                  :options="formattedUsers"
                  :option-renderer="usersRenderer"
                  :label-renderer="usersRenderer"
                  :multiple="true"
                  :searchable="true"
                  :placeholder="i18n.t('experiments.canvas.new_my_module_modal.assigned_users_placeholder')"
                  :tagsView="true" ></SelectDropdown>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.cancel') }}</button>
            <button type="submit" :disabled="!validName" class="btn btn-primary">
              {{ i18n.t('experiments.canvas.new_my_module_modal.create') }}
            </button>
          </div>
        </div>
      </form>
    </div>
  </div>
</template>

<script>
/* global HelperModule SmartAnnotation */

import axios from '../../../packs/custom_axios.js';
import modalMixin from '../../shared/modal_mixin';
import DateTimePicker from '../../shared/date_time_picker.vue';
import SelectDropdown from '../../shared/select_dropdown.vue';

export default {
  name: 'NewModal',
  props: {
    createUrl: String,
    projectTagsUrl: String,
    assignedUsersUrl: String
  },
  components: {
    DateTimePicker,
    SelectDropdown
  },
  data() {
    return {
      name: '',
      dueDate: null,
      tags: [],
      users: [],
      allTags: [],
      allUsers: []
    };
  },
  computed: {
    validName() {
      return this.name.length > 0;
    },
    formattedTags() {
      return this.allTags.map((tag) => (
        [
          tag.id,
          tag.attributes.name,
          tag.attributes.color
        ]
      ));
    },
    formattedUsers() {
      return this.allUsers.map((user) => (
        [
          user.id,
          user.attributes.name,
          user.attributes.avatar_url
        ]
      ));
    }
  },
  mounted() {
    SmartAnnotation.init($(this.$refs.description), false);
    this.loadTags();
    this.loadUsers();
  },
  mixins: [modalMixin],

  methods: {
    submit() {
      axios.post(this.createUrl, {
        my_module: {
          name: this.name,
          due_date: this.dueDate,
          user_ids: this.users,
          tag_ids: this.tags
        }
      }).then(() => {
        this.$emit('create');
      }).catch((error) => {
        HelperModule.flashAlertMsg(error.response.data.message, 'danger');
      });
    },
    setDueDate(value) {
      this.dueDate = this.formatDate(value);
    },
    setTags(tags) {
      this.tags = tags;
    },
    setUsers(users) {
      this.users = users;
    },
    formatDate(date) {
      if (!(date instanceof Date)) return null;

      const y = date.getFullYear();
      const m = date.getMonth() + 1;
      const d = date.getDate();
      const hours = date.getHours();
      const mins = date.getMinutes();
      return `${y}/${m}/${d} ${hours}:${mins}`;
    },
    loadTags() {
      axios.get(this.projectTagsUrl).then((response) => {
        this.allTags = response.data.data;
      });
    },
    loadUsers() {
      axios.get(this.assignedUsersUrl).then((response) => {
        this.allUsers = response.data.data;
      });
    },
    tagsRenderer(tag) {
      return `<div class="flex items-center gap-2">
                <span class="w-4 h-4 rounded-full" style="background-color: ${tag[2]}"></span>
                ${tag[1]}
              </div>`;
    },
    usersRenderer(user) {
      return `<div class="flex items-center gap-2">
                <img class="w-6 h-6 rounded-full" src="${user[2]}">
                ${user[1]}
              </div>`;
    }
  }
};
</script>
