<template>
  <div class="user-sessions my-8">
    <h3>{{ i18n.t('users.registrations.edit.sessions.title') }}</h3>
    <div v-if="loading" class="sci-loader"></div>
    <template v-else-if="sessions.length > 0">
      <p>{{ i18n.t('users.registrations.edit.sessions.description') }}</p>
      <div class="w-fit max-w-full overflow-x-auto">
        <table class="w-full">
          <thead>
            <tr class="bg-sn-super-light-grey">
              <th class="p-2 font-normal whitespace-nowrap">{{ i18n.t('users.registrations.edit.sessions.user_agent') }}</th>
              <th class="p-2 font-normal whitespace-nowrap">{{ i18n.t('users.registrations.edit.sessions.ip_address') }}</th>
              <th class="p-2 font-normal whitespace-nowrap">{{ i18n.t('users.registrations.edit.sessions.signed_in_at') }}</th>
              <th class="p-2 font-normal whitespace-nowrap">{{ i18n.t('users.registrations.edit.sessions.last_seen') }}</th>
              <th class="p-2"></th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="userSession in sessions"
                :key="userSession.id"
                class="border-0 border-b border-solid border-sn-super-light-grey hover:bg-sn-super-light-grey"
                :data-e2e="`e2e-TR-userSessions-${userSession.id}`">
              <td class="p-2 break-all min-w-[20rem]">
                {{ userSession.user_agent }}
                <span v-if="userSession.current" class="ml-2 text-sn-grey whitespace-nowrap">
                  ({{ i18n.t('users.registrations.edit.sessions.current') }})
                </span>
              </td>
              <td class="p-2 whitespace-nowrap">{{ userSession.ip_address || '-' }}</td>
              <td class="p-2 whitespace-nowrap">{{ userSession.signed_in_at }}</td>
              <td class="p-2 whitespace-nowrap">{{ userSession.last_seen_at }}</td>
              <td class="p-2">
                <button v-if="!userSession.current"
                        class="btn btn-secondary btn-sm whitespace-nowrap"
                        :data-e2e="`e2e-BT-userSessions-terminate-${userSession.id}`"
                        @click="terminateSession(userSession)">
                  {{ i18n.t('users.registrations.edit.sessions.terminate') }}
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <button v-if="hasOtherSessions"
              class="btn btn-secondary mt-4"
              data-e2e="e2e-BT-userSessions-terminateOthers"
              @click="terminateOtherSessions">
        {{ i18n.t('users.registrations.edit.sessions.terminate_others') }}
      </button>
    </template>
    <p v-else>{{ i18n.t('users.registrations.edit.sessions.empty_state') }}</p>

    <ConfirmationModal
      ref="terminateModal"
      :title="i18n.t('users.registrations.edit.sessions.terminate_modal.title')"
      :description="i18n.t('users.registrations.edit.sessions.terminate_modal.description')"
      :confirmText="i18n.t('users.registrations.edit.sessions.terminate_modal.confirm')"
      confirmClass="btn btn-danger"
      e2eValue="terminateSessionModal"
    />
    <ConfirmationModal
      ref="terminateOthersModal"
      :title="i18n.t('users.registrations.edit.sessions.terminate_others_modal.title')"
      :description="i18n.t('users.registrations.edit.sessions.terminate_others_modal.description')"
      :confirmText="i18n.t('users.registrations.edit.sessions.terminate_others_modal.confirm')"
      confirmClass="btn btn-danger"
      e2eValue="terminateOtherSessionsModal"
    />
  </div>
</template>

<script>
/* global HelperModule */
import axios from '../../packs/custom_axios.js';
import ConfirmationModal from '../shared/confirmation_modal.vue';

export default {
  name: 'UserSessions',
  components: { ConfirmationModal },
  props: {
    sessionsUrl: { type: String, required: true },
    destroyOthersUrl: { type: String, required: true }
  },
  data() {
    return {
      sessions: [],
      loading: true
    };
  },
  computed: {
    hasOtherSessions() {
      return this.sessions.some((s) => !s.current);
    }
  },
  created() {
    this.loadSessions();
  },
  methods: {
    loadSessions() {
      this.loading = true;
      axios.get(this.sessionsUrl).then((response) => {
        this.sessions = response.data.data;
      }).catch(() => {
        HelperModule.flashAlertMsg(this.i18n.t('users.registrations.edit.sessions.error'), 'danger');
      }).finally(() => {
        this.loading = false;
      });
    },
    async terminateSession(userSession) {
      const confirmed = await this.$refs.terminateModal.show();
      if (!confirmed) return;

      axios.delete(userSession.destroy_url).then(() => {
        this.sessions = this.sessions.filter((s) => s.id !== userSession.id);
        HelperModule.flashAlertMsg(this.i18n.t('users.registrations.edit.sessions.terminated'), 'success');
      }).catch((error) => {
        HelperModule.flashAlertMsg(
          error.response?.data?.error || this.i18n.t('users.registrations.edit.sessions.error'),
          'danger'
        );
      });
    },
    async terminateOtherSessions() {
      const confirmed = await this.$refs.terminateOthersModal.show();
      if (!confirmed) return;

      axios.delete(this.destroyOthersUrl).then(() => {
        this.sessions = this.sessions.filter((s) => s.current);
        HelperModule.flashAlertMsg(this.i18n.t('users.registrations.edit.sessions.others_terminated'), 'success');
      }).catch(() => {
        HelperModule.flashAlertMsg(this.i18n.t('users.registrations.edit.sessions.error'), 'danger');
      });
    }
  }
};
</script>
