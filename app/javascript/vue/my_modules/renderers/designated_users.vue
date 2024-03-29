<template>
  <div v-if="params.data.designated_users.length > 0 || params.data.permissions.manage_designated_users">
    <GeneralDropdown @open="loadUsers" @close="closeFlyout" position="right">
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
        <div v-if="canManage" class="sci-input-container-v2 left-icon mb-1 -mx-2.5">
          <input type="text"
                  v-model="query"
                  class="sci-input-field"
                  autofocus="true"
                  :placeholder="i18n.t('general.search')" />
          <i class="sn-icon sn-icon-search"></i>
        </div>
        <perfect-scrollbar class="flex flex-col relative max-h-80 overflow-y-auto max-w-[280px] pt-1 -mx-2.5 pr-4 pl-2 gap-y-px">
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
    loadUsers() {
      axios.get(`${this.params.data.urls.users_list}`, {
        params: {
          query: this.query,
          skip_unassigned: !this.canManage
        }
      })
        .then((response) => {
          let result = response.data;

          if (!Array.isArray(result)) result = [];

          this.allUsers = result;
          this.selectedUsers = result.filter((item) => this.users.some((user) => user.id === item.value));
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
