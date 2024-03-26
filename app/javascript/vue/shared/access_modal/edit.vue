<template>
  <div>
    <div v-if="roles.length > 0 && visible && default_role" class="p-2 flex items-center gap-2 border-solid border-0 border-b border-b-sn-sleepy-grey">
      <div>
        <img src="/images/icon/team.png" class="rounded-full w-8 h-8">
      </div>
      <div>
        {{ i18n.t('access_permissions.everyone_else', { team_name: params.object.team }) }}
      </div>
      <GeneralDropdown @open="loadUsers" @close="closeFlyout">
        <template v-slot:field>
          <i class="sn-icon sn-icon-info"></i>
        </template>
        <template v-slot:flyout>
          <perfect-scrollbar class="flex flex-col max-h-96 max-w-[280px] relative pr-4 gap-y-px">
            <div v-for="user in this.autoAssignedUsers"
                :key="user.attributes.user.id"
                :title="user.attributes.user.name"
                class="rounded px-3 py-2.5 flex items-center hover:no-underline leading-5 gap-2">
              <img :src="user.attributes.user.avatar_url" class="w-6 h-6 rounded-full">
              <span class="truncate">{{ user.attributes.user.name }}</span>
            </div>
          </perfect-scrollbar>
        </template>
      </GeneralDropdown>
      <MenuDropdown
        v-if="params.object.top_level_assignable && params.object.urls.update_access"
        class="ml-auto"
        :listItems="rolesFromatted"
        :btnText="this.roles.find((role) => role[0] == default_role)[1]"
        :position="'right'"
        :caret="true"
        @setRole="(...args) => this.changeDefaultRole(...args)"
        @removeRole="() => this.changeDefaultRole()"
      ></MenuDropdown>
      <div class="ml-auto btn btn-light pointer-events-none" v-else>
        {{ this.roles.find((role) => role[0] == default_role)[1] }}
        <div class="h-6 w-6"></div>
      </div>
    </div>
    <perfect-scrollbar class="h-[50vh] relative">
      <div v-for="userAssignment in manuallyAssignedUsers"
            :key="userAssignment.id"
            class="p-2 flex items-center gap-2">
        <div>
          <img :src="userAssignment.attributes.user.avatar_url" class="rounded-full w-8 h-8">
        </div>
        <div class="truncate">
          <div class="flex flex-row gap-2">
            <div class="truncate"
                :title="userAssignment.attributes.user.name"
            >{{ userAssignment.attributes.user.name }}</div>
            <div v-if="userAssignment.attributes.current_user" class="text-nowrap">
              {{ `(${i18n.t('access_permissions.you')})` }}
            </div>
          </div>
          <div class="text-xs text-sn-grey text-nowrap">{{ userAssignment.attributes.inherit_message }}</div>
        </div>
        <MenuDropdown
          v-if="!userAssignment.attributes.last_owner && params.object.urls.update_access"
          class="ml-auto"
          :listItems="rolesFromatted"
          :btnText="userAssignment.attributes.user_role.name"
          :position="'right'"
          :caret="true"
          @setRole="(...args) => this.changeRole(userAssignment.attributes.user.id, ...args)"
          @removeRole="() => this.removeRole(userAssignment.attributes.user.id)"
        ></MenuDropdown>
        <div class="ml-auto btn btn-light pointer-events-none" v-else>
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
import GeneralDropdown from '../../shared/general_dropdown.vue';
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
    }
  },
  mounted() {
    this.getAssignedUsers();
    this.getRoles();
  },
  watch: {
    reloadUsers() {
      if (this.reloadUsers) {
        this.getAssignedUsers();
      }
    }
  },
  components: {
    MenuDropdown,
    GeneralDropdown
  },
  computed: {
    rolesFromatted() {
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
          params: role[0]
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
    manuallyAssignedUsers() {
      return this.assignedUsers.filter((user) => (
        user.attributes?.assigned === 'manually'
      ));
    },
    autoAssignedUsers() {
      return this.assignedUsers.filter((user) => (
        user.attributes?.assigned === 'automatically'
      ));
    }
  },
  data() {
    return {
      assignedUsers: [],
      roles: []

    };
  },
  methods: {
    getAssignedUsers() {
      axios.get(this.params.object.urls.show_access)
        .then((response) => {
          this.assignedUsers = response.data.data;
          this.$emit('usersReloaded');
        });
    },
    getRoles() {
      axios.get(this.params.roles_path)
        .then((response) => {
          this.roles = response.data.data;
        });
    },
    changeRole(id, roleId) {
      axios.put(this.params.object.urls.update_access, {
        user_assignment: {
          user_id: id,
          user_role_id: roleId
        }
      }).then(() => {
        this.$emit('modified');
        this.getAssignedUsers();
      });
    },
    removeRole(id) {
      axios.delete(this.params.object.urls.update_access, {
        data: {
          user_id: id
        }
      }).then((response) => {
        this.$emit('modified');
        HelperModule.flashAlertMsg(response.data.message, 'success');
        this.getAssignedUsers();
      });
    },
    changeDefaultRole(roleId) {
      axios.put(this.params.object.urls.default_public_user_role_path, {
        object: {
          default_public_user_role_id: roleId || ''
        }
      }).then((response) => {
        this.$emit('modified');
        if (!roleId) {
          this.$emit('changeVisibility', false, null);
        } else {
          this.$emit('changeVisibility', true, roleId);
        }
        if (response.data.message) {
          HelperModule.flashAlertMsg(response.data.message, 'success');
        }
      });
    },
    removeDefaultRole() {
    }
  }
};
</script>
