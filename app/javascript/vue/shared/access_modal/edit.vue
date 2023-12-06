<template>
  <div>
    <div class="modal-header">
      <button type="button" class="close" data-dismiss="modal" aria-label="Close"><i class="sn-icon sn-icon-close"></i></button>
      <h4 class="modal-title truncate !block">
        {{ i18n.t(`access_permissions.${params.object.type}.modals.edit_modal.title`, {resource_name: params.object.name}) }}
      </h4>
    </div>
    <div class="modal-body">
      <div class="h-[60vh] overflow-y-auto">
        <div v-for="userAssignment in manuallyAssignedUsers" :key="userAssignment.id" class="p-2 flex items-center gap-2">
          <div>
            <img :src="userAssignment.attributes.user.avatar_url" class="rounded-full w-8 h-8">
          </div>
          <div>{{ userAssignment.attributes.user.name }}</div>
          <MenuDropdown
            v-if="!userAssignment.attributes.last_owner"
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
        <div v-if="roles.length > 0 && visible" class="p-2 flex items-center gap-2">
          <div>
            <img src="/images/icon/team.png" class="rounded-full w-8 h-8">
          </div>
          <div>
            {{ i18n.t('access_permissions.everyone_else', { team_name: params.object.team }) }}
          </div>
          <i class="sn-icon sn-icon-info" :title='this.autoAssignedUsers.map((ua) => ua.attributes.user.name).join("\u000d")'></i>
          <MenuDropdown
            class="ml-auto"
            :listItems="rolesFromatted"
            :btnText="this.roles.find((role) => role[0] == default_role)[1]"
            :position="'right'"
            :caret="true"
            @setRole="(...args) => this.changeDefaultRole(...args)"
            @removeRole="() => this.changeDefaultRole()"
          ></MenuDropdown>
        </div>
      </div>
    </div>
    <div v-if="params.object.top_level_assignable" class="modal-footer">
      <button class="btn-light ml-auto btn" @click="$emit('changeMode', 'newView')">
        <i class="sn-icon sn-icon-new-task"></i>
        {{ i18n.t('access_permissions.grant_access') }}
      </button >
    </div>
  </div>
</template>

<script>
import MenuDropdown from "../../shared/menu_dropdown.vue";
import axios from '../../../packs/custom_axios.js';

export default {
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
    }
  },
  emits: ['changeMode', 'modified'],
  mounted() {
    this.getAssignedUsers();
    this.getRoles();
  },
  components: {
    MenuDropdown,
  },
  computed: {
    rolesFromatted() {
      let roles = this.roles.map((role) => {
        return {
          emit: 'setRole',
          text: role[1],
          params: role[0]
        }
      });

      roles.push({
        dividerBefore: true,
        emit: 'removeRole',
        text: this.i18n.t('access_permissions.remove_access'),
      });

      return roles
    },
    manuallyAssignedUsers() {
      return this.assignedUsers.filter((user) => {
        return user.attributes.assigned === 'manually';
      });
    },
    autoAssignedUsers() {
      return this.assignedUsers.filter((user) => {
        return user.attributes.assigned === 'automatically';
      });
    },
  },
  data() {
    return {
      assignedUsers: [],
      roles: [],

    };
  },
  methods: {
    getAssignedUsers() {
      axios.get(this.params.object.urls.show_access)
        .then((response) => {
          this.assignedUsers = response.data.data;
        })
    },
    getRoles() {
      axios.get(this.params.roles_path)
        .then((response) => {
          this.roles = response.data.data;
        })
    },
    changeRole(id, role_id) {
      axios.put(this.params.object.urls.show_access, {
        user_assignment: {
          user_id: id,
          user_role_id: role_id
        }
      }).then((response) => {
        this.$emit('modified');
        this.getAssignedUsers();
      })
    },
    removeRole(id) {
      axios.delete(this.params.object.urls.show_access, {
        data: {
          user_id: id
        }
      }).then((response) => {
        this.$emit('modified');
        HelperModule.flashAlertMsg(response.data.message, 'success');
        this.getAssignedUsers();
      })
    },
    changeDefaultRole(role_id) {
      axios.put(this.params.object.urls.default_public_user_role_path, {
        project: {
          default_public_user_role_id: role_id || ''
        }
      }).then((response) => {
        this.$emit('modified');
        if (!role_id) {
          this.$emit('changeVisibility', false, null);
        } else {
          this.$emit('changeVisibility', true, role_id);
        }
        if (response.data.message) {
          HelperModule.flashAlertMsg(response.data.message, 'success');
        }
      })
    },
    removeDefaultRole() {
    },
  }

}
</script>
