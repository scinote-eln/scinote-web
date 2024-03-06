<template>
  <div class="mb-6">
    <div class="sci-label mb-2">
      {{ i18n.t('access_permissions.partials.new_assignments_form.grant_access') }}
    </div>
    <GeneralDropdown ref="dropdown" @open="$emit('assigningNewUsers', true)" @close="$emit('assigningNewUsers', false)" :fieldOnlyOpen="true" :fixed-width="true">
      <template v-slot:field>
        <div class="sci-input-container-v2 left-icon">
          <input type="text" v-model="query" class="sci-input-field"
                  :placeholder="i18n.t('access_permissions.partials.new_assignments_form.find_people_html')" />
          <i class="sn-icon sn-icon-search"></i>
        </div>
      </template>
      <template v-slot:flyout>
        <div v-if="!visible && roles.length > 0" class="py-2 flex border-solid border-0 border-b border-b-sn-sleepy-grey items-center gap-2">
          <div>
            <img src="/images/icon/team.png" class="rounded-full w-8 h-8">
          </div>
          <div>
            {{ i18n.t('user_assignment.assign_all_team_members') }}
          </div>
          <MenuDropdown
            class="ml-auto"
            :listItems="rolesFromatted"
            btnText="Assign"
            :position="'right'"
            :caret="true"
            @setRole="(...args) => this.assignRole('all', ...args)"
          ></MenuDropdown>
        </div>
        <perfect-scrollbar class="max-h-80 relative">
          <div v-for="user in filteredUsers" :key="user.id" class="py-2 flex items-center w-full">
            <div>
              <img :src="user.attributes.avatar_url" class="rounded-full w-8 h-8">
            </div>
            <div class="truncate ml-2" :title="user.attributes.name">{{ user.attributes.name }}</div>
            <div v-if="user.attributes.current_user" class="text-nowrap">
              {{ i18n.t('access_permissions.you') }}
            </div>
            <MenuDropdown
              class="ml-auto"
              :listItems="rolesFromatted"
              btnText="Assign"
              :position="'right'"
              :caret="true"
              @setRole="(...args) => this.assignRole(user.id, ...args)"
            ></MenuDropdown>
          </div>
          <div v-if="filteredUsers.length === 0" class="p-2 flex items-center w-full">
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
    }
  },
  mounted() {
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
    }
  },
  data() {
    return {
      unAssignedUsers: [],
      roles: [],
      query: ''
    };
  },
  watch: {
    reloadUsers() {
      if (this.reloadUsers) {
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
    getRoles() {
      axios.get(this.params.roles_path)
        .then((response) => {
          this.roles = response.data.data;
        });
    },
    assignRole(id, roleId) {
      axios.post(this.params.object.urls.create_access, {
        user_assignment: {
          user_id: id,
          user_role_id: roleId
        }
      })
        .then((response) => {
          this.$emit('modified');
          HelperModule.flashAlertMsg(response.data.message, 'success');
          this.getUnAssignedUsers();
          this.query = '';
          this.$refs.dropdown.closeMenu();

          if (id === 'all') {
            this.$emit('changeVisibility', true, roleId);
          }
        });
    }
  }
};
</script>
