<template>
  <div class="flex flex-col mb-5">
    <h2>{{ i18n.t('users.settings.teams.preferences.title') }}</h2>
    <div>
      <div v-for="(items, sectionKey) in settings" :key="`section-${sectionKey}`" class="flex flex-col bg-sn-white gap-4 p-4 w-full rounded">
        <h5>{{ i18n.t(`users.settings.teams.preferences.sections.${sectionKey}.title`)}}</h5>

        <div
          v-for="(item, itemKey) in items"
          :key="`pref-${sectionKey}-${itemKey}`"
          class="flex justify-between max-w-3xl border-0 border-t border-solid border-sn-super-light-grey">
            <div class="text-base py-3 pl-2">{{ item.label }}</div>
            <div class="flex-shrink-0 flex items-center py-3">
              <div class="sci-toggle-checkbox-container">
                <input
                  :id="`team-pref-${sectionKey}-${itemKey}`"
                  :name="`team-pref-${sectionKey}-${itemKey}`"
                  class="sci-toggle-checkbox"
                  type="checkbox"
                  :checked="!!item.value"
                  :disabled="!item.can_update || loadingSettings"
                  @change="handleToggleChange(sectionKey, itemKey, item, $event)" />
                <span class="sci-toggle-checkbox-label"></span>
              </div>
            </div>
          </div>
      </div>
    </div>

    <ConfirmationModal
      ref="confirmationModal"
      :e2e-value="confirmationModalState.e2eValue"
      :title="confirmationModalState.title"
      :description="confirmationModalState.description"
      :confirm-text="confirmationModalState.button"
      confirm-class="btn btn-danger"
    />
  </div>
</template>

<script>
import axios from "../../packs/custom_axios.js";
import ConfirmationModal from "../shared/confirmation_modal.vue";
import escapeHtml from "../shared/escape_html.js";
import {
  available_settings_team_path,
  update_setting_team_path
} from "../../routes.js";

export default {
  name: "TeamPreferences",
  components: {
    ConfirmationModal
  },
  props: {
    teamId: {
      type: [Number, String],
      required: true
    }
  },
  data() {
    return {
      loadingSettings: true,
      settings: {},
      confirmationModalState: {
        e2eValue: "",
        title: "",
        description: "",
        button: ""
      }
    };
  },
  created() {
    this.fetchAvailableSettings();
  },
  methods: {
    fetchAvailableSettings() {
      this.loadingSettings = true;

      axios
        .get(available_settings_team_path({ id: this.teamId }))
        .then(({ data }) => {
          this.settings = data || {};
        })
        .catch(() => {})
        .finally(() => {
          this.loadingSettings = false;
        });
    },
    handleToggleChange(sectionKey, itemKey, item, event) {
      if (this.loadingSettings || !item.can_update) return;

      const currentValue = !!item.value;
      const nextValue = !!event.target.checked;
      const shouldConfirm =
        !!item.confirm && currentValue === true && nextValue === false;

      if (!shouldConfirm) return this.updateSetting(sectionKey, itemKey, item, nextValue);

      // revert until user confirms
      event.target.checked = true;
      item.value = true;

      const modal = this.$refs.confirmationModal;
      if (!modal || typeof modal.show !== "function") return;

      this.confirmationModalState = {
        e2eValue: `confirm-${sectionKey}-${itemKey}`,
        title: item.confirm.title,
        description: item.confirm.description,
        button: item.confirm.button
      };

      modal.show().then(confirmed => {
        if (!confirmed) return;
        this.updateSetting(sectionKey, itemKey, item, false);
      });
    },
    updateSetting(sectionKey, itemKey, item, value) {
      const previousValue = !!item.value;
      item.value = !!value;

      axios
        .put(update_setting_team_path({ id: this.teamId }), {
          section: sectionKey,
          key: itemKey,
          value
        })
        .catch(() => {
          item.value = previousValue;
          HelperModule.flashAlertMsg(this.i18n.t('general.error'), 'danger');
        });
    }
  }
};
</script>
