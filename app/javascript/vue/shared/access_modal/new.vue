<template>
  <div>
    <div class="modal-header">
      <button type="button" class="close" data-dismiss="modal" aria-label="Close">
        <i class="sn-icon sn-icon-close"></i>
      </button>
      <h4 class="modal-title truncate flex items-center gap-4">
        {{ i18n.t('access_permissions.partials.new_assignments_form.title', {resource_name: params.object.name}) }}
        <button class="close" @click="$emit('changeMode', 'editView')">
          <i class="sn-icon sn-icon-left"></i>
        </button>
      </h4>
    </div>
    <div class="modal-body">
      <div class="mb-4">
        <div class="sci-input-container-v2 left-icon">
          <input type="text" v-model="query" class="sci-input-field"
                 autofocus="true"
                 :placeholder="i18n.t('access_permissions.partials.new_assignments_form.find_people_html')" />
          <i class="sn-icon sn-icon-search"></i>
        </div>
      </div>
      <div class="h-[60vh] overflow-y-auto">
        <div v-if="!visible && roles.length > 0" class="p-2 flex items-center gap-2">
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
        <div v-for="user in filteredUsers" :key="user.id" class="p-2 flex items-center gap-2">
          <div>
            <img :src="user.attributes.avatar_url" class="rounded-full w-8 h-8">
          </div>
          <div>{{ user.attributes.name }}</div>
          <MenuDropdown
            class="ml-auto"
            :listItems="rolesFromatted"
            btnText="Assign"
            :position="'right'"
            :caret="true"
            @setRole="(...args) => this.assignRole(user.id, ...args)"
          ></MenuDropdown>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
/* global HelperModule */
import MenuDropdown from '../menu_dropdown.vue';
import axios from '../../../packs/custom_axios.js';

export default {
  props: {
    params: {
      type: Object,
      required: true,
    },
    visible: {
      type: Boolean,
    },
    default_role: {
      type: Number,
    },
  },
  emits: ['changeMode'],
  mounted() {
    this.getUnAssignedUsers();
    this.getRoles();
  },
  components: {
    MenuDropdown,
  },
  computed: {
    rolesFromatted() {
      return this.roles.map((role) => (
        {
          emit: 'setRole',
          text: role[1],
          params: role[0],
        }
      ));
    },
    filteredUsers() {
      return this.unAssignedUsers.filter((user) => (
        user.attributes.name.toLowerCase().includes(this.query.toLowerCase())
      ));
    },
  },
  data() {
    return {
      unAssignedUsers: [],
      roles: [],
      query: '',
    };
  },
  methods: {
    getUnAssignedUsers() {
      axios.get(this.params.object.urls.new_access)
        .then((response) => {
          this.unAssignedUsers = response.data.data;
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
          user_role_id: roleId,
        },
      })
        .then((response) => {
          this.$emit('modified');
          HelperModule.flashAlertMsg(response.data.message, 'success');
          this.getUnAssignedUsers();

          if (id === 'all') {
            this.$emit('changeVisibility', true, roleId);
          }
        });
    },
  },
};
</script>
