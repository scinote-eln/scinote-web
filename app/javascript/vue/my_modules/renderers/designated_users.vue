<template>
  <GeneralDropdown @open="loadUsers" @close="closeFlyout">
    <template v-slot:field>
      <div v-if="!params.data.folder" class="flex items-center gap-1 cursor-pointer h-9" @click="openAccessModal">
        <div v-for="(user, i) in visibleUsers" :key="i" :title="user.full_name">
          <img :src="user.avatar" class="w-7 h-7" />
        </div>
        <div v-if="hiddenUsers.length > 0" :title="hiddenUsersTitle"
            class="flex shrink-0 items-center justify-center w-7 h-7 text-xs
                   rounded-full bg-sn-dark-grey text-sn-white">
          +{{ hiddenUsers.length }}
        </div>
        <div class="flex items-center shrink-0 justify-center w-7 h-7 rounded-full bg-sn-light-grey text-sn-dark-grey">
          <i class="sn-icon sn-icon-new-task"></i>
        </div>
      </div>
    </template>
    <template v-slot:flyout>
      <div class="sci-input-container-v2 left-icon mb-2.5">
        <input type="text"
                v-model="query"
                class="sci-input-field"
                autofocus="true"
                :placeholder="i18n.t('experiments.table.search')" />
        <i class="sn-icon sn-icon-search"></i>
      </div>
      <div class="h-64 overflow-y-auto">
        <div v-for="user in allUsers"
            :key="user.value"
            @click="selectUser(user)"
            :class="{ '!bg-sn-super-light-blue': selectedUsers.includes(user.value) }"
            class="whitespace-nowrap rounded px-3 py-2.5 flex items-center gap-2
                    hover:no-underline cursor-pointer hover:bg-sn-super-light-grey leading-5"
          >
            <div class="sci-checkbox-container">
              <input type="checkbox" class="sci-checkbox" :checked="selectedUsers.includes(user.value)" />
              <label class="sci-checkbox-label"></label>
            </div>
            <img :src="user.params.avatar_url" class="w-7 h-7" />
            {{ user.label }}
        </div>
      </div>
    </template>
  </GeneralDropdown>
</template>

<script>

import axios from '../../../packs/custom_axios.js';
import GeneralDropdown from '../../shared/general_dropdown.vue';

export default {
  name: 'DesignatedUsersRenderer',
  props: {
    params: {
      required: true
    }
  },
  components: {
    GeneralDropdown
  },
  computed: {
    users() {
      return this.params.data.designated_users;
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
  created() {
    this.selectedUsers = this.users.map((user) => (user.id));
  },
  methods: {
    loadUsers() {
      axios.get(`${this.params.data.urls.users_list}?query=${this.query}`)
        .then((response) => {
          this.allUsers = response.data;
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
      this.changed = true;

      if (this.selectedUsers.includes(user.value)) {
        axios.delete(user.params.unassign_url, {
          table: true
        }).then(() => {
          this.selectedUsers = this.selectedUsers.filter((id) => id !== user.value);
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
          this.selectedUsers.push(user.value);
        });
      }
    }
  }
};
</script>
