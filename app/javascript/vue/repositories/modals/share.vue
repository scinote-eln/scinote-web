<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title truncate !block">
            {{ i18n.t('repositories.index.modal_share.title', {name: repository.name }) }}
          </h4>
        </div>
        <div class="modal-body">
          <div class="grid grid-cols-3 gap-2">
            <div class="col-span-2">
              {{ i18n.t("repositories.index.modal_share.share_with_team") }}
            </div>
            <div class="text-center">
              {{ i18n.t("repositories.index.modal_share.can_edit") }}
            </div>
            <div class="col-span-2 flex items-center h-9 gap-1">
              <span class="sci-checkbox-container">
                <input type="checkbox" class="sci-checkbox" v-model="sharedWithAllRead" />
                <span class="sci-checkbox-label"></span>
              </span>
              {{ i18n.t("repositories.index.modal_share.all_teams") }}
            </div>
            <div class="flex justify-center items-center">
              <span v-if="sharedWithAllRead" class="sci-toggle-checkbox-container">
                <input type="checkbox"
                       class="sci-toggle-checkbox"
                       :disabled="!repository.shareable_write"
                       v-model="sharedWithAllWrite" />
                <span class="sci-toggle-checkbox-label"></span>
              </span>
            </div>
            <template v-for="team in shareableTeams">
              <div class="col-span-2 flex items-center h-9 gap-1">
                <span class="sci-checkbox-container" :class="{'opacity-0 pointer-events-none': sharedWithAllRead}">
                  <input type="checkbox" class="sci-checkbox" v-model="team.attributes.private_shared_with" />
                  <span class="sci-checkbox-label"></span>
                </span>
                {{ team.attributes.name }}
              </div>
              <div class="flex justify-center items-center">
                <span v-if="team.attributes.private_shared_with"
                      :class="{'opacity-0 pointer-events-none': sharedWithAllRead}"
                      class="sci-toggle-checkbox-container">
                  <input type="checkbox"
                        class="sci-toggle-checkbox"
                        @change="permission_changes[team.id] = true"
                        :disabled="!repository.shareable_write"
                        v-model="team.attributes.private_shared_with_write" />
                  <span class="sci-toggle-checkbox-label"></span>
                </span>
              </div>
            </template>
          </div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.cancel') }}</button>
          <button class="btn btn-primary" @click="submit" type="submit">
            {{ i18n.t('repositories.index.modal_share.submit') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
/* global HelperModule */

import axios from '../../../packs/custom_axios.js';
import modalMixin from '../../shared/modal_mixin';

export default {
  name: 'ShareRepositoryModal',
  props: {
    repository: Object
  },
  mixins: [modalMixin],
  data() {
    return {
      sharedWithAllRead: this.repository.shared_read || this.repository.shared_write,
      sharedWithAllWrite: this.repository.shared_write,
      shareableTeams: [],
      permission_changes: {}
    };
  },
  mounted() {
    this.getTeams();
  },
  methods: {
    getTeams() {
      axios.get(this.repository.urls.shareable_teams).then((response) => {
        this.shareableTeams = response.data.data;
      });
    },
    submit() {
      const data = {
        select_all_teams: this.sharedWithAllRead,
        select_all_write_permission: this.sharedWithAllWrite,
        share_team_ids: this.shareableTeams.filter((team) => team.attributes.private_shared_with).map((team) => team.id),
        write_permissions: this.shareableTeams.filter((team) => team.attributes.private_shared_with_write).map((team) => team.id),
        permission_changes: this.permission_changes
      };
      axios.post(this.repository.urls.share, data).then(() => {
        HelperModule.flashAlertMsg(this.i18n.t(
          'repositories.index.modal_share.success_message',
          { inventory_name: this.repository.name }
        ), 'success');
        this.$emit('share');
      });
    }
  }
};
</script>
