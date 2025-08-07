<template>
  <div>
    <div v-if="params.data.team_users_count > users.length && params.data.permissions.manage">
      <GeneralDropdown @open="loadUsers" @close="closeFlyout" position="right">
        <template v-slot:field>
          <div class="flex items-center gap-1 cursor-pointer h-9">
            <div v-for="(user, i) in visibleUsers" :key="i" :title="user.full_name">
              <img :src="user.avatar" class="w-7 h-7 rounded-full" />
            </div>
            <div v-if="hiddenUsers.length > 0" :title="hiddenUsersTitle"
                class="flex shrink-0 items-center justify-center w-7 h-7 text-xs rounded-full bg-sn-dark-grey text-sn-white">
              +{{ hiddenUsers.length }}
            </div>
            <div class="flex items-center shrink-0 justify-center w-7 h-7 rounded-full border-dashed bg-sn-white text-sn-sleepy-grey border-sn-sleepy-grey">
              <i class="sn-icon sn-icon-new-task"></i>
            </div>
          </div>
        </template>
        <template v-slot:flyout>
          <div class="px-2">
            <div class="sci-input-container-v2 left-icon mb-1 -mx-2.5">
              <input type="text"
                      v-model="query"
                      class="sci-input-field"
                      autofocus="true"
                      :placeholder="i18n.t('general.search')" />
              <i class="sn-icon sn-icon-search"></i>
            </div>
          </div>
          <div class="flex flex-col relative max-h-80 overflow-y-auto max-w-[280px] pt-1 -mx-2.5 px-2 gap-y-px">
            <div v-for="user in unassginedUsers"
                :key="user.value"
                @click="selectUser(user)"
                :class="{
                  '!bg-sn-super-light-blue': selectedUsers.some(({ value }) => value === user[0])
                }"
                class="whitespace-nowrap rounded py-2.5 flex items-center gap-2
                        hover:no-underline leading-5 cursor-pointer hover:bg-sn-super-light-grey px-3"
              >
                <div class="sci-checkbox-container">
                  <input type="checkbox" class="sci-checkbox" :checked="selectedUsers.some(({ value }) => value === user[0])" />
                  <label class="sci-checkbox-label"></label>
                </div>
                <img :src="user[2].avatar" class="w-6 h-6 rounded-full" />
                <span class="truncate">{{ user[1] }}</span>
            </div>
          </div>
        </template>
      </GeneralDropdown>
    </div>
    <div v-else>
      <div class="flex items-center gap-1 cursor-pointer h-9">
        <div v-for="(user, i) in visibleUsers" :key="i" :title="user.full_name">
          <img :src="user.avatar" class="w-7 h-7 rounded-full" />
        </div>
        <div v-if="hiddenUsers.length > 0" :title="hiddenUsersTitle"
            class="flex shrink-0 items-center justify-center w-7 h-7 text-xs rounded-full bg-sn-dark-grey text-sn-white">
          +{{ hiddenUsers.length }}
        </div>
      </div>
    </div>
  </div>
</template>

<script>

import GeneralDropdown from '../../shared/general_dropdown.vue';
import axios from '../../../packs/custom_axios.js';

export default {
  name: 'MembersRenderer',
  props: {
    params: {
      required: true
    }
  },
  components: {
    GeneralDropdown
  },
  data() {
    return {
      query: '',
      unassginedUsers: [],
      selectedUsers: []
    };
  },
  watch: {
    query() {
      this.loadUsers();
    }
  },
  computed: {
    users() {
      return this.params.value || [];
    },
    visibleUsers() {
      return this.users.slice(0, 4);
    },
    hiddenUsers() {
      return this.users.slice(4);
    },
    hiddenUsersTitle() {
      return this.hiddenUsers.map((user) => user.full_name).join('\u000d');
    }
  },
  methods: {
    selectUser(user) {
      const index = this.selectedUsers.findIndex(({ value }) => value === user[0]);
      if (index > -1) {
        this.selectedUsers.splice(index, 1);
      } else {
        this.selectedUsers.push(user[0]);
      }
    },
    loadUsers() {
      axios.get(this.params.data.urls.unassigned_users, { params: { query: this.query } })
        .then((response) => {
          this.unassginedUsers = response.data.data
        })
    },
    closeFlyout() {
      if (this.selectedUsers.length > 0) {
        this.params.dtComponent.$emit('assignUsers', this.params, this.selectedUsers);
      }
    }
  }
};
</script>
