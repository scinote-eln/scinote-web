<template>
  <div v-if="params.data.designated_users.length > 0 || params.data.permissions.manage_designated_users">
    <GeneralDropdown @open="() => loadUsers(true)" @close="closeFlyout">
      <template v-slot:field>
        <div v-if="!params.data.folder" class="flex items-center gap-1 cursor-pointer h-9" @click="openAccessModal">
          <div v-for="(user, i) in visibleUsers" :key="i" :title="user.full_name">
            <img :src="user.avatar" class="w-7 h-7 rounded-full" />
          </div>
          <div v-if="hiddenUsers.length > 0" :title="hiddenUsersTitle"
              class="flex shrink-0 items-center justify-center w-7 h-7 text-xs
                    rounded-full bg-sn-dark-grey text-sn-white">
            +{{ hiddenUsers.length }}
          </div>
          <div v-if="canManage" class="flex items-center shrink-0 justify-center w-7 h-7 rounded-full bg-sn-light-grey text-sn-dark-grey">
            <i class="sn-icon sn-icon-new-task"></i>
          </div>
        </div>
      </template>
      <template v-slot:flyout>
        <div v-if="canManage" class="sci-input-container-v2 left-icon mb-1">
          <input type="text"
                  v-model="query"
                  class="sci-input-field"
                  autofocus="true"
                  :placeholder="i18n.t('experiments.table.search')" />
          <i class="sn-icon sn-icon-search"></i>
        </div>
        <perfect-scrollbar class="relative max-h-96 overflow-y-auto max-w-[280px] pr-4 gap-y-px">
          <div v-for="user in allUsers"
              :key="user.value"
              @click="selectUser(user)"
              :class="{
                '!bg-sn-super-light-blue': selectedUsers.some(({ value }) => value === user.value) && canManage,
                'cursor-pointer hover:bg-sn-super-light-grey px-3': canManage
              }"
              class="whitespace-nowrap rounded py-2.5 flex items-center gap-2
                      hover:no-underline leading-5"
            >
              <div v-if="canManage" class="sci-checkbox-container">
                <input type="checkbox" class="sci-checkbox" :checked="selectedUsers.some(({ value }) => value === user.value)" />
                <label class="sci-checkbox-label"></label>
              </div>
              <img :src="user.params.avatar_url" class="w-6 h-6 rounded-full" />
              <span class="truncate">{{ user.label }}</span>
          </div>
        </perfect-scrollbar>
      </template>
    </GeneralDropdown>
  </div>
  <span v-else>{{ i18n.t('experiments.table.not_set') }}</span>
</template>

<script>

import axios from '../../../packs/custom_axios.js';
import GeneralDropdown from '../../shared/general_dropdown.vue';
import { PerfectScrollbar } from 'vue3-perfect-scrollbar';

export default {
  name: 'DesignatedUsersRenderer',
  props: {
    params: {
      required: true
    }
  },
  components: {
    GeneralDropdown,
    PerfectScrollbar
  },
  computed: {
    users() {
      return this.params.data.designated_users;
    },
    canManage() {
      return this.params.data.permissions.manage_designated_users;
    },
    visibleUsers() {
      return this.users.slice(0, 4);
    },
    hiddenUsers() {
      return this.users.slice(4);
    },
    hiddenUsersTitle() {
      return this.hiddenUsers.map((user) => user.name).join('\u000d');
    }
  },
  data() {
    return {
      selectedUsers: [],
      allUsers: [],
      query: '',
      changed: false
    };
  },
  watch: {
    query() {
      this.loadUsers();
    }
  },
  methods: {
    loadUsers(setSelectedUsers = false) {
      axios.get(`${this.params.data.urls.users_list}`, {
        params: {
          query: this.query,
          skip_unassigned: !this.canManage
        }
      })
        .then((response) => {
          if (setSelectedUsers) {
            this.selectedUsers = response.data.users.filter((item) => this.users.some((user) => user.id === item.value));
            this.allUsers = response.data.users;
            this.flyoutLoaded = true;
          } else {
            const nonAssignedUsers = response.data.users.filter((item) => !this.selectedUsers.some(({ value }) => value === item.value));
            this.allUsers = this.selectedUsers.concat(nonAssignedUsers);
          }
        });
    },
    closeFlyout() {
      this.query = '';
      if (this.changed) {
        this.params.dtComponent.updateTable();
        this.changed = false;
      }
    },
    selectUser(user) {
      if (!this.canManage) {
        return;
      }

      this.changed = true;

      if (this.selectedUsers.some(({ value }) => value === user.value)) {
        axios.delete(user.params.unassign_url, {
          table: true
        }).then(() => {
          this.selectedUsers = this.selectedUsers.filter(({ value }) => value !== user.value);
        });
      } else {
        axios.post(user.params.assign_url, {
          table: true,
          user_my_module: {
            my_module_id: this.params.data.id,
            user_id: user.value
          }
        }).then((response) => {
          this.allUsers.find((u) => u.value === user.value).params.unassign_url = response.data.unassign_url;
          this.selectedUsers.push(user);
        });
      }
    }
  }
};
</script>
