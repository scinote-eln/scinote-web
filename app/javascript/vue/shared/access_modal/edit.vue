<template>
  <div>
    <perfect-scrollbar class="h-[50vh] relative">
      <div v-if="roles.length > 0 && visible && default_role" class="p-2 flex items-center gap-2 border-solid border-0 border-b border-b-sn-sleepy-grey">
        <div>
          <img src="/images/icon/team.png" class="rounded-full w-8 h-8" :data-e2e="`e2e-IC-${dataE2e}-everyoneElse-team`">
        </div>
        <div :data-e2e="`e2e-TX-${dataE2e}-everyoneElse`">
          {{ i18n.t('access_permissions.everyone_else', { team_name: params.object.current_team || params.object.team }) }}
        </div>
        <GeneralDropdown>
          <template v-slot:field>
            <i class="sn-icon sn-icon-info" :data-e2e="`e2e-IC-${dataE2e}-everyoneElse-info`"></i>
          </template>
          <template v-slot:flyout>
            <div class="flex flex-col max-h-96 max-w-[280px] relative pr-4 gap-y-px overflow-y-auto">
              <div v-for="user in this.teamUsers"
                  :key="user.id"
                  :title="user.attributes.name"
                  class="rounded px-3 py-2.5 flex items-center hover:no-underline leading-5 gap-2">
                <img
                  :src="user.attributes.avatar_url"
                  class="w-6 h-6 rounded-full"
                  :data-e2e="`e2e-IC-${dataE2e}-everyoneElse-${user.attributes.name.replace(/\W/g, '')}`"
                >
                <span class="truncate" :data-e2e="`e2e-TX-${dataE2e}-everyoneElse-${user.attributes.name.replace(/\W/g, '')}`">{{ user.attributes.name }}</span>
              </div>
            </div>
          </template>
        </GeneralDropdown>
        <MenuDropdown
          v-if="params.object.urls.update_access"
          class="ml-auto"
          :listItems="rolesFromatted(default_role)"
          :btnText="this.roles.find((role) => role[0] == default_role)[1]"
          :position="'right'"
          :caret="true"
          :data-e2e="`e2e-DD-${dataE2e}-everyoneElse-roles`"
          @setRole="(...args) => this.changeDefaultRole(...args)"
          @removeRole="() => this.changeDefaultRole()"
        ></MenuDropdown>
        <div class="ml-auto btn btn-light pointer-events-none" v-else>
          {{ this.roles.find((role) => role[0] == default_role)[1] }}
          <div class="h-6 w-6"></div>
        </div>
      </div>
      <div v-for="userGroupAssignment in assignedUserGroups"
            :key="userGroupAssignment.id"
            class="p-2 flex items-center gap-2">
        <div>
          <img
            class="rounded-full w-8 h-8"
            src="/images/icon/group.svg"
          >
        </div>
        <div class="truncate">
          <div class="flex flex-row gap-2 items-center">
            <div class="truncate"
                :title="userGroupAssignment.attributes.user_group.name"
            >{{ userGroupAssignment.attributes.user_group.name }}</div>
            <div
              v-if="userGroupAssignment.attributes.current_user"
              class="text-nowrap"
            >
              {{ `(${i18n.t('access_permissions.you')})` }}
            </div>
            <GeneralDropdown @open="loadUsers(userGroupAssignment.attributes.user_group.id)" @close="groupUsers = []">
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
          </div>
          <div class="text-xs text-sn-grey text-nowrap">
            {{ userGroupAssignment.attributes.inherit_message }}
          </div>
        </div>
        <MenuDropdown
          v-if="params.object.urls.update_access"
          class="ml-auto"
          :listItems="rolesFromatted(userGroupAssignment.attributes.user_role.id)"
          :btnText="userGroupAssignment.attributes.user_role.name"
          :position="'right'"
          :caret="true"
          @setRole="(...args) => this.changeRole('userGroup', userGroupAssignment.attributes.user_group.id, ...args)"
          @removeRole="() => this.removeRole('userGroup', userGroupAssignment.attributes.user_group.id)"
        ></MenuDropdown>
        <div v-else class="ml-auto btn btn-light pointer-events-none">
          {{ userGroupAssignment.attributes.user_role.name }}
          <div class="h-6 w-6"></div>
        </div>
      </div>
      <div v-for="userAssignment in assignedUsers"
            :key="userAssignment.id"
            class="p-2 flex items-center gap-2">
        <div>
          <img
            class="rounded-full w-8 h-8"
            :src="userAssignment.attributes.user.avatar_url"
            :data-e2e="`e2e-IC-${dataE2e}-${userAssignment.attributes.user.name.replace(/\W/g, '')}`"
          >
        </div>
        <div class="truncate">
          <div class="flex flex-row gap-2 items-center">
            <div class="truncate"
                :title="userAssignment.attributes.user.name"
                :data-e2e="`e2e-TX-${dataE2e}-${userAssignment.attributes.user.name.replace(/\W/g, '')}-name`"
            >{{ userAssignment.attributes.user.name }}</div>
            <div
              v-if="userAssignment.attributes.current_user"
              class="text-nowrap"
              :data-e2e="`e2e-TX-${dataE2e}-${userAssignment.attributes.user.name.replace(/\W/g, '')}-currentUserLabel`"
            >
              {{ `(${i18n.t('access_permissions.you')})` }}
            </div>
          </div>
          <div class="text-xs text-sn-grey text-nowrap" :data-e2e="`e2e-TX-${dataE2e}-${userAssignment.attributes.user.name.replace(/\W/g, '')}-inheritLabel`">
            {{ userAssignment.attributes.inherit_message }}
          </div>
        </div>
        <MenuDropdown
          v-if="!userAssignment.attributes.last_owner && params.object.urls.update_access && !(userAssignment.attributes.current_user && userAssignment.attributes.inherit_message)"
          class="ml-auto"
          :listItems="rolesFromatted(userAssignment.attributes.user_role.id)"
          :btnText="userAssignment.attributes.user_role.name"
          :position="'right'"
          :caret="true"
          :data-e2e="`e2e-DD-${dataE2e}-${userAssignment.attributes.user.name.replace(/\W/g, '')}-role`"
          @setRole="(...args) => this.changeRole('user', userAssignment.attributes.user.id, ...args)"
          @removeRole="() => this.removeRole('user', userAssignment.attributes.user.id)"
        ></MenuDropdown>
        <div v-else class="ml-auto btn btn-light pointer-events-none" :data-e2e="`e2e-TX-${dataE2e}-${userAssignment.attributes.user.name.replace(/\W/g, '')}-role`">
          {{ userAssignment.attributes.user_role.name }}
          <div class="h-6 w-6"></div>
        </div>
      </div>
    </perfect-scrollbar>
  </div>
</template>

<script>
/* global HelperModule */
import MenuDropdown from '../menu_dropdown.vue';
import GeneralDropdown from '../general_dropdown.vue';
import axios from '../../../packs/custom_axios.js';
import {
  current_team_users_teams_path
} from '../../../routes.js';

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
    this.getAssignedUserGroups();
    this.getAssignedUsers();
    this.getTeamUsers();
    this.getRoles();
  },
  watch: {
    reloadUsers() {
      if (this.reloadUsers) {
        this.getAssignedUserGroups();
        this.getAssignedUsers();
      }
    }
  },
  components: {
    MenuDropdown,
    GeneralDropdown
  },
  data() {
    return {
      teamUsers: [],
      assignedUsers: [],
      assignedUserGroups: [],
      roles: [],
      groupUsers: []

    };
  },
  methods: {
    getTeamUsers() {
      axios.get(current_team_users_teams_path({ format: 'json' })).then((response) => {
        this.teamUsers = response.data.data;
      });
    },
    getAssignedUsers() {
      axios.get(this.params.object.urls.show_access)
        .then((response) => {
          this.assignedUsers = response.data.data;
          this.$emit('usersReloaded');
        });
    },
    getAssignedUserGroups() {
      axios.get(this.params.object.urls.show_user_group_assignments_access)
        .then((response) => {
          this.assignedUserGroups = response.data.data;
        });
    },
    rolesFromatted(activeRoleId = null) {
      let roles = [];

      if (!this.params.object.top_level_assignable) {
        roles.push({
          emit: 'setRole',
          text: this.i18n.t('access_permissions.reset'),
          params: 'reset'
        });
      }

      roles = roles.concat(this.roles.map((role, index) => (
        {
          dividerBefore: !this.params.object.top_level_assignable && index === 0,
          emit: 'setRole',
          text: role[1],
          params: role[0],
          active: (activeRoleId === role[0])
        }
      )));

      if (this.params.object.top_level_assignable) {
        roles.push({
          dividerBefore: true,
          emit: 'removeRole',
          text: this.i18n.t('access_permissions.remove_access')
        });
      }

      return roles;
    },
    getRoles() {
      axios.get(this.params.object.urls.user_roles)
        .then((response) => {
          this.roles = response.data.data;
        });
    },
    changeRole(type, id, roleId) {
      const assignmentKey = type === 'userGroup' ? 'user_group_id' : 'user_id';

      axios.put(this.params.object.urls.update_access, {
        user_assignment: {
          [assignmentKey]: id,
          user_role_id: roleId
        }
      }).then(() => {
        this.$emit('modified');

        if (type === 'userGroup') {
          this.getAssignedUserGroups();
        } else {
          this.getAssignedUsers();
        }
      });
    },
    removeRole(type, id) {
      const assignmentKey = type === 'userGroup' ? 'user_group_id' : 'user_id';

      axios.delete(this.params.object.urls.update_access, {
        data: {
          user_assignment: {
            [assignmentKey]: id
          }
        }
      }).then((response) => {
        this.$emit('modified');
        HelperModule.flashAlertMsg(response.data.message, 'success');
        if (type === 'userGroup') {
          this.getAssignedUserGroups();
        } else {
          this.getAssignedUsers();
        }
      });
    },
    changeDefaultRole(roleId) {
      let response;

      if (!roleId) {
        response = axios.delete(this.params.object.urls.update_access,
          {
            data: {
              user_assignment: {
                user_id: 'all'
              }
            }
          }
        );
      } else {
        response = axios.put(this.params.object.urls.update_access, {
          user_assignment: {
            user_id: 'all',
            user_role_id: roleId
          }
        });
      }

      response.then((response) => {
        this.$emit('modified');
        if (!roleId) {
          this.$emit('changeVisibility', false, null);
        } else {
          this.$emit('changeVisibility', true, response.data.user_role_id);
        }
        if (response.data.message) {
          HelperModule.flashAlertMsg(response.data.message, 'success');
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
