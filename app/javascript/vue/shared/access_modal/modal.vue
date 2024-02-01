<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button"
                  class="close"
                  data-dismiss="modal"
                  aria-label="Close"><i class="sn-icon sn-icon-close"></i></button>
          <h4 class="modal-title truncate !block">
            {{ i18n.t(`access_permissions.${params.object.type}.modals.edit_modal.title`, {
              resource_name: params.object.name
            }) }}
          </h4>
        </div>
        <div class="modal-body">
          <AssignFlyout
            v-if="params.object.urls.new_access"
            :params="params"
            :visible="visible"
            :default_role="default_role"
            :reloadUsers="reloadUnAssignedUsers"
            @modified="modified = true; reloadUsers = true"
            @assigningNewUsers="(v) => { assigningNewUsers = v }"
            @usersReloaded="reloadUnAssignedUsers = false"
            @changeVisibility="changeVisibility"
          />
          <h5 class="py-2.5">
            {{ i18n.t('access_permissions.partials.new_assignments_form.people_with_access') }}
          </h5>
          <editView
            :class="{'opacity-50 pointer-events-none': assigningNewUsers}"
            :params="params"
            :visible="visible"
            :default_role="default_role"
            :reloadUsers="reloadUsers"
            @modified="modified = true; reloadUnAssignedUsers = true"
            @usersReloaded="reloadUsers = false"
            @changeVisibility="changeVisibility"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script>

import SelectDropdown from '../select_dropdown.vue';
import modalMixin from '../modal_mixin';
import editView from './edit.vue';
import AssignFlyout from './assign_flyout.vue';

export default {
  emits: ['modified', 'usersReloaded', 'changeVisibility'],
  name: 'AccessModal',
  props: {
    params: {
      type: Object,
      required: true
    }
  },
  mixins: [modalMixin],
  components: {
    SelectDropdown,
    editView,
    AssignFlyout
  },
  data() {
    return {
      mode: 'editView',
      modified: false,
      visible: false,
      default_role: null,
      reloadUsers: false,
      assigningNewUsers: false,
      reloadUnAssignedUsers: false
    };
  },
  mounted() {
    this.visible = !this.params.object.hidden;
    this.default_role = this.params.object.default_public_user_role_id;
  },
  beforeUnmount() {
    if (this.modified) {
      this.$emit('refresh');
    }
  },
  methods: {
    changeMode(mode) {
      this.mode = mode;
    },
    changeVisibility(status, role) {
      this.visible = status;
      this.default_role = role;
    }
  }
};
</script>
