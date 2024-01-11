<template>
  <div class="content-pane flexible with-grey-background">
    <div class="content-header">
      <div class="title-row">
        <h1 class="mt-0">
          {{ i18n.t('users.settings.account.preferences.title') }}
        </h1>
      </div>
    </div>
    <div class="p-4 mb-4 bg-sn-white rounded">
      <div>
        <h2 class="mt-0">{{ i18n.t("users.settings.account.preferences.edit.time_zone_label") }}</h2>
        <div class="text-sn-dark-grey mb-4">
          <p>{{ i18n.t("users.settings.account.preferences.edit.time_zone_sublabel") }}</p>
        </div>
        <SelectSearch
          class="max-w-[40ch]"
          :value="selectedTimeZone"
          @change="setTimeZone"
          :options="timeZones"
        />
      </div>
      <div class="sci-divider my-6 inline-block"></div>
      <div>
        <h2 class="mt-0">{{ i18n.t("users.settings.account.preferences.edit.date_format_label") }}</h2>
        <div class="text-sn-dark-grey mb-4">
          <p>{{ i18n.t("users.settings.account.preferences.edit.date_format_sublabel") }}</p>
        </div>
        <SelectSearch
          class="max-w-[40ch]"
          :value="selectedDateFormat"
          @change="setDateFormat"
          :options="dateFormats"
        />
      </div>
    </div>
    <div class="p-4 mb-4 bg-sn-white rounded">
      <h2 class="mt-0">{{ i18n.t('notifications.title') }}</h2>
      <div class="text-sn-dark-grey">
        <p>{{ i18n.t('notifications.sub_title') }}</p>
      </div>
      <table v-if="notificationsSettings">
        <template v-for="(_subGroups, group) in notificationsGroups" :key="group">
          <div class="contents">
            <tr>
              <td colspan=3 class="pt-6"><h3>{{ i18n.t(`notifications.groups.${group}`) }}</h3></td>
            </tr>
            <tr>
              <td></td>
              <td class="p-2.5 text-base w-32">{{ i18n.t('notifications.in_app') }}</td>
              <td class="p-2.5 text-base w-32">{{ i18n.t('notifications.email') }}</td>
            </tr>
          </div>
          <template v-for="(_notifications, subGroup, i) in notificationsGroups[group]" :key="subGroup">
            <tr v-if="subGroup !== 'always_on'"
                class="text-base border-transparent border-b-sn-super-light-grey border-solid"
                :class="{'border-t-sn-super-light-grey': i == 0}"
            >
              <td class="p-2.5 pr-10">{{ i18n.t(`notifications.sub_groups.${subGroup}`) }}</td>
              <td class="p-2.5">
                <div class="sci-toggle-checkbox-container">
                  <input v-model="notificationsSettings[subGroup]['in_app']" type="checkbox" class="sci-toggle-checkbox" @change="setNotificationsSettings"/>
                  <label class="sci-toggle-checkbox-label"></label>
                </div>
              </td>
              <td class="p-2.5">
                <div class="sci-toggle-checkbox-container">
                  <input v-model="notificationsSettings[subGroup]['email']" type="checkbox" class="sci-toggle-checkbox" @change="setNotificationsSettings"/>
                  <label class="sci-toggle-checkbox-label"></label>
                </div>
              </td>
            </tr>
          </template>
        </template>
      </table>
    </div>
  </div>
</template>

<script>

import SelectSearch from "../shared/legacy/select_search.vue";
import axios from '../../packs/custom_axios.js';

export default {
  name: 'UserPreferences',
  props: {
    userSettings: Object,
    timeZones: Array,
    dateFormats: Array,
    updateUrl: String,
    notificationsGroups: Object
  },
  data() {
    return {
      selectedTimeZone: null,
      selectedDateFormat: null,
      notificationsSettings: null
    };
  },
  created() {
    this.selectedTimeZone = this.userSettings.time_zone;
    this.selectedDateFormat = this.userSettings.date_format;
    this.notificationsSettings = { ...this.emptySettings, ...this.userSettings.notifications_settings };
  },
  computed: {
    emptySettings() {
      const settings = {};
      for (const group in this.notificationsGroups) {
        for (const subGroup in this.notificationsGroups[group]) {
          settings[subGroup] = { in_app: false, email: false };
        }
      }
      return settings;
    }
  },
  components: {
    SelectSearch
  },
  methods: {
    setTimeZone(value) {
      this.selectedTimeZone = value;
      axios.put(this.updateUrl, {
        user: { time_zone: value }
      });
    },
    setDateFormat(value) {
      this.selectedDateFormat = value;
      axios.put(this.updateUrl, {
        user: { date_format: value }
      });
    },
    setNotificationsSettings() {
      axios.put(this.updateUrl, {
        user: { notifications_settings: this.notificationsSettings }
      });
    }
  }
};
</script>
