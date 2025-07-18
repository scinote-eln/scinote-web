<template>
  <div class="mb-6">
    <div class="sci-label mb-2" :data-e2e="`e2e-TX-${dataE2e}-grantAccessLabel`">
      {{ i18n.t('access_permissions.partials.new_assignments_form.grant_access') }}
    </div>
    <GeneralDropdown ref="dropdown" @open="$emit('assigningNewUsers', true)" @close="$emit('assigningNewUsers', false)" :fieldOnlyOpen="true" :fixed-width="true">
      <template v-slot:field>
        <div class="sci-input-container-v2 left-icon">
          <input
            type="text"
            v-model="query"
            class="sci-input-field"
            :placeholder="i18n.t('access_permissions.partials.new_assignments_form.find_people_html')"
            :data-e2e="`e2e-IF-${dataE2e}-searchUsers`"
          />
          <i class="sn-icon sn-icon-search" :data-e2e="`e2e-IC-${dataE2e}-searchUsers`"></i>
        </div>
      </template>
      <template v-slot:flyout>
        <div v-if="!visible && roles.length > 0" class="py-2 flex border-solid border-0 border-b border-b-sn-sleepy-grey items-center gap-2">
          <div>
            <img src="/images/icon/team.png" class="rounded-full w-8 h-8" :data-e2e="`e2e-IC-${dataE2e}-grantAccessTeam`">
          </div>
          <div :data-e2e="`e2e-TX-${dataE2e}-grantAccessTeam`">
            {{ i18n.t('user_assignment.assign_all_team_members') }}
          </div>
          <MenuDropdown
            class="ml-auto"
            :listItems="rolesFromatted"
            btnText="Assign"
            :position="'right'"
            :caret="true"
            :data-e2e="`e2e-DD-${dataE2e}-grantAccessTeam`"
            @setRole="(...args) => this.assignRole('user', 'all', ...args)"
          ></MenuDropdown>
        </div>
        <perfect-scrollbar class="max-h-80 relative">
          <div v-for="userGroup in filteredUserGroups" :key="userGroup.id" class="py-2 flex items-center w-full">
            <div>
              <img src="/images/icon/group.png" class="rounded-full w-8 h-8">
            </div>
            <div
              class="truncate ml-2"
              :title="userGroup.attributes.name"
            >
              {{ userGroup.attributes.name }}
            </div>
            <GeneralDropdown @open="loadUsers(userGroup.id)" @close="groupUsers = []">
              <template v-slot:field>
                <i class="sn-icon sn-icon-info"></i>
              </template>
              <template v-slot:flyout>
                <perfect-scrollbar class="flex flex-col max-h-96 max-w-[280px] relative pr-4 gap-y-px">
                  <div v-for="user in this.groupUsers"
                       :key="user.attributes.id"
                       :title="user.attributes.name"
                       class="rounded px-3 py-2.5 flex items-center hover:no-underline leading-5 gap-2">
                    <img
                      :src="user.attributes.avatar_url"
                      class="w-6 h-6 rounded-full"
                    >
                    <span class="truncate">{{ user.attributes.name }}</span>
                  </div>
                </perfect-scrollbar>
              </template>
            </GeneralDropdown>
            <MenuDropdown
              class="ml-auto"
              :listItems="rolesFromatted"
              btnText="Assign"
              :position="'right'"
              :caret="true"
              @setRole="(...args) => this.assignRole('userGroup',userGroup.id, ...args)"
            ></MenuDropdown>
          </div>
          <div v-for="user in filteredUsers" :key="user.id" class="py-2 flex items-center w-full">
            <div>
              <img :src="user.attributes.avatar_url" class="rounded-full w-8 h-8" :data-e2e="`e2e-IC-${dataE2e}-${user.attributes.name.replace(/\W/g, '')}-grantAccess`">
            </div>
            <div
              class="truncate ml-2"
              :title="user.attributes.name"
              :data-e2e="`e2e-TX-${dataE2e}-${user.attributes.name.replace(/\W/g, '')}-grantAccess-name`"
            >
              {{ user.attributes.name }}
            </div>
            <div v-if="user.attributes.current_user" class="text-nowrap ml-1" :data-e2e="`e2e-TX-${dataE2e}-${user.attributes.name.replace(/\W/g, '')}-grantAccess-permission`">
              {{ `(${i18n.t('access_permissions.you')})` }}
            </div>
            <MenuDropdown
              class="ml-auto"
              :listItems="rolesFromatted"
              btnText="Assign"
              :position="'right'"
              :caret="true"
              :data-e2e="`e2e-DD-${dataE2e}-${user.attributes.name.replace(/\W/g, '')}-grantAccess`"
              @setRole="(...args) => this.assignRole('user', user.id, ...args)"
            ></MenuDropdown>
          </div>
          <div v-if="filteredUsers?.length === 0 && filteredUserGroups?.length === 0" class="p-2 flex items-center w-full">
            {{ i18n.t('access_permissions.no_results') }}
          </div>
        </perfect-scrollbar>
      </template>
    </GeneralDropdown>
  </div>
</template>

<script>
/* global HelperModule */
import MenuDropdown from '../menu_dropdown.vue';
import GeneralDropdown from '../general_dropdown.vue';
import axios from '../../../packs/custom_axios.js';

export default {
  emits: ['modified', 'usersReloaded', 'changeVisibility', 'assigningNewUsers'],
  props: {
    params: {
      type: Object,
      required: true
    },
    visible: {
      type: Boolean
    },
    default_role: {
      type: Number
    },
    reloadUsers: {
      type: Boolean
    },
    dataE2e: {
      type: String,
      default: ''
    }
  },
  mounted() {
    this.getUnAssignedUserGroups();
    this.getUnAssignedUsers();
    this.getRoles();
  },
  components: {
    MenuDropdown,
    GeneralDropdown
  },
  computed: {
    rolesFromatted() {
      return this.roles.map((role) => (
        {
          emit: 'setRole',
          text: role[1],
          params: role[0]
        }
      ));
    },
    filteredUsers() {
      return this.unAssignedUsers.filter((user) => (
        user.attributes.name.toLowerCase().includes(this.query.toLowerCase())
      ));
    },
    filteredUserGroups() {
      return this.unAssignedUserGroups.filter((userGroup) => (
        userGroup.attributes.name.toLowerCase().includes(this.query.toLowerCase())
      ));
    }
  },
  data() {
    return {
      unAssignedUsers: [],
      unAssignedUserGroups: [],
      groupUsers: [],
      roles: [],
      query: ''
    };
  },
  watch: {
    reloadUsers() {
      if (this.reloadUsers) {
        this.getUnAssignedUserGroups();
        this.getUnAssignedUsers();
      }
    }
  },
  methods: {
    getUnAssignedUsers() {
      axios.get(this.params.object.urls.new_access)
        .then((response) => {
          this.unAssignedUsers = response.data.data;
          this.$emit('usersReloaded');
        });
    },
    getUnAssignedUserGroups() {
      axios.get(this.params.object.urls.unassigned_user_groups)
        .then((response) => {
          this.unAssignedUserGroups = response.data.data;
        });
    },
    getRoles() {
      axios.get(this.params.object.urls.user_roles)
        .then((response) => {
          this.roles = response.data.data;
        });
    },
    assignRole(type, id, roleId) {
      const assignmentKey = type === 'userGroup' ? 'user_group_id' : 'user_id';

      axios.post(this.params.object.urls.create_access, {
        user_assignment: {
          [assignmentKey]: id,
          user_role_id: roleId
        }
      })
        .then((response) => {
          this.$emit('modified');
          HelperModule.flashAlertMsg(response.data.message, 'success');
          this.query = '';
          this.$refs.dropdown.closeMenu();

          if (type === 'userGroup') {
            this.getUnAssignedUserGroups();
          } else {
            this.getUnAssignedUsers();

            if (id === 'all') {
              this.$emit('changeVisibility', true, roleId);
            }
          }
        });
    },
    loadUsers(userGroupId) {
      axios.get(this.params.object.urls.user_group_members, {
        params: {
          user_group_id: userGroupId
        }
      })
        .then((response) => {
          this.groupUsers = response.data.data;
        });
    }
  }
};
</script>
