<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <form @submit.prevent="submit">
        <div class="modal-content" data-e2e="e2e-MD-newProtocol">
          <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-label="Close" data-e2e="e2e-BT-newProtocolModal-close">
              <i class="sn-icon sn-icon-close"></i>
            </button>
            <h4 class="modal-title truncate !block" id="edit-project-modal-label" data-e2e="e2e-TX-newProtocolModal-title">
              {{ i18n.t("protocols.new_protocol_modal.title_new") }}
            </h4>
          </div>
          <div class="modal-body">
            <div class="mb-6">
              <label class="sci-label" data-e2e="e2e-TX-newProtocolModal-inputLabel">{{ i18n.t("protocols.new_protocol_modal.name_label") }}</label>
              <div class="sci-input-container-v2" :class="{'error': error}" :data-error="error">
                <input type="text" v-model="name"
                       class="sci-input-field"
                       autofocus="true" ref="input"
                       data-e2e="e2e-IF-newProtocolModal-name"
                       :placeholder="i18n.t('protocols.new_protocol_modal.name_placeholder')" />
              </div>
            </div>
            <div class="flex gap-2 text-xs items-center">
              <div class="sci-checkbox-container">
                <input type="checkbox" class="sci-checkbox" v-model="visible" value="visible" data-e2e="e2e-CB-newProtocolModal-grantAccess"/>
                <span class="sci-checkbox-label"></span>
              </div>
              <span v-html="i18n.t('protocols.new_protocol_modal.access_label')" data-e2e="e2e-TX-newProtocolModal-grantAccess"></span>
            </div>
            <div class="mt-6" :class="{'hidden': !visible}">
              <label class="sci-label">{{ i18n.t("protocols.new_protocol_modal.role_label") }}</label>
              <SelectDropdown
                :options="userRoles"
                :value="defaultRole"
                :data-e2e="`e2e-DD-newProtocolModal-defaultUserRole`"
                @change="changeRole"
              />
            </div>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-dismiss="modal" data-e2e="e2e-BT-newProtocolModal-cancel">{{ i18n.t('general.cancel') }}</button>
            <button class="btn btn-primary" type="submit" :disabled="submitting || (visible && !defaultRole) || !validName" data-e2e="e2e-BT-newProtocolModal-create">
              {{ i18n.t('protocols.new_protocol_modal.create_new') }}
            </button>
          </div>
        </div>
      </form>
    </div>
  </div>
</template>

<script>
/* global GLOBAL_CONSTANTS */

import SelectDropdown from '../../shared/select_dropdown.vue';
import axios from '../../../packs/custom_axios.js';
import modalMixin from '../../shared/modal_mixin';

export default {
  name: 'NewProtocolModal',
  props: {
    createUrl: String,
    userRolesUrl: String
  },
  mixins: [modalMixin],
  components: {
    SelectDropdown
  },
  watch: {
    visible(newValue) {
      if (newValue) {
        [this.defaultRole] = this.userRoles.find((role) => role[1] === 'Viewer');
      } else {
        this.defaultRole = null;
      }
    }
  },
  mounted() {
    this.fetchUserRoles();
  },
  computed: {
    validName() {
      return this.name.length >= GLOBAL_CONSTANTS.NAME_MIN_LENGTH;
    }
  },
  data() {
    return {
      name: '',
      visible: false,
      defaultRole: null,
      userRoles: [],
      error: null,
      submitting: false
    };
  },
  methods: {
    submit() {
      this.submitting = true;

      axios.post(this.createUrl, {
        protocol: {
          name: this.name,
          visibility: (this.visible ? 'visible' : 'hidden'),
          default_public_user_role_id: this.defaultRole
        }
      }).then(() => {
        this.error = null;
        this.$emit('create');
        this.submitting = false;
      }).catch((error) => {
        this.submitting = false;
        this.error = error.response.data.error;
      });
    },
    changeRole(role) {
      this.defaultRole = role;
    },
    fetchUserRoles() {
      if (this.userRolesUrl) {
        axios.get(this.userRolesUrl)
          .then((response) => {
            this.userRoles = response.data.data;
          });
      }
    }
  }
};
</script>
