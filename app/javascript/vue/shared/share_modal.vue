<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title truncate !block">
            {{ i18n.t('modal_share.title', {object_name: object.name }) }}
          </h4>
        </div>
        <div class="modal-body">
          <div class="grid grid-cols-3 gap-2">
            <div class="col-span-2">
              {{ i18n.t("modal_share.share_with_team") }}
            </div>
            <div class="text-center">
              {{ i18n.t("modal_share.can_edit") }}
            </div>
            <div v-if="globalShareEnabled" class="col-span-2 flex items-center h-9 gap-1">
              <span class="sci-checkbox-container">
                <input type="checkbox" class="sci-checkbox" v-model="sharedWithAllRead" />
                <span class="sci-checkbox-label"></span>
              </span>
              {{ i18n.t("modal_share.all_teams") }}
            </div>
            <div v-if="globalShareEnabled" class="flex justify-center items-center">
              <span v-if="sharedWithAllRead" class="sci-toggle-checkbox-container">
                <input type="checkbox"
                       class="sci-toggle-checkbox"
                       :disabled="!object.shareable_write"
                       v-model="sharedWithAllWrite" />
                <span class="sci-toggle-checkbox-label"></span>
              </span>
            </div>
            <template v-for="team in shareableTeams">
              <div class="col-span-2 flex items-center h-9 gap-1" :class="{ 'hidden': !team.attributes.readable && !team.attributes.private_shared_with }">
                <span class="sci-checkbox-container" :class="{'opacity-0 pointer-events-none': sharedWithAllRead}">
                  <input :disabled="!team.attributes.readable" type="checkbox" class="sci-checkbox" v-model="team.attributes.private_shared_with" />
                  <span class="sci-checkbox-label"></span>
                </span>
                {{ team.attributes.name || `(${i18n.t('teams.private_team')})` }}
              </div>
              <div class="flex justify-center items-center">
                <span v-if="team.attributes.private_shared_with"
                      :class="{'opacity-0 pointer-events-none': sharedWithAllRead || !team.attributes.readable}"
                      class="sci-toggle-checkbox-container">
                  <input type="checkbox"
                        class="sci-toggle-checkbox"
                        :disabled="!object.shareable_write"
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
            {{ i18n.t('modal_share.submit') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
/* global HelperModule */

import axios from '../../packs/custom_axios.js';
import modalMixin from './modal_mixin';

export default {
  name: 'ShareObjectModal',
  props: {
    object: Object,
    globalShareEnabled: { type: Boolean, default: false },
    confirmationModal: { type: Object }
  },
  mixins: [modalMixin],
  data() {
    return {
      sharedWithAllRead: this.object.shared_read || this.object.shared_write,
      sharedWithAllWrite: this.object.shared_write,
      initialState: {},
      shareableTeams: []
    };
  },
  mounted() {
    this.initTeams();
  },
  computed: {
    willUnshare() {
      if (this.globalShareEnabled && !this.sharedWithAllRead && this.initialState.sharedWithAllRead) return true;

      // true if any team would switch from shared to unshared, based on initial state
      return this.shareableTeams.some((t) => {
        return this.initialState.shareableTeams.find((it) => t.id === it.id).attributes.private_shared_with && !t.attributes.private_shared_with;
      });
    }
  },
  methods: {
    initTeams() {
      axios.get(this.object.urls.shareable_teams).then((response) => {
        this.initialState = {
          shareableTeams: JSON.parse(JSON.stringify(response.data.data)), // object needs to be deep cloned to get rid of references
          sharedWithAllRead: this.sharedWithAllRead,
          sharedWithAllWrite: this.sharedWithAllWrite
        };
        this.shareableTeams = response.data.data;
      });
    },
    async submit() {
      $(this.$refs.modal).hide();

      if (this.confirmationModal ? !this.willUnshare || await this.confirmationModal.show() : true) {
        this.doRequest();
      } else {
        $(this.$refs.modal).show();
      }
    },
    doRequest() {
      const data = {
        select_all_teams: this.sharedWithAllRead,
        select_all_write_permission: this.sharedWithAllWrite,
        team_share_params: this.sharedWithAllRead ? [] : this.shareableTeams.map((team) => { return { id: team.id, ...team.attributes } })
      };
      axios.post(this.object.urls.share, data).then(() => {
        HelperModule.flashAlertMsg(this.i18n.t(
          'modal_share.success_message',
          { object_name: this.object.name }
        ), 'success');
        this.$emit('share');
      });
    }
  }
};
</script>
