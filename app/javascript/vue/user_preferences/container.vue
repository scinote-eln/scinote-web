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
      <div class="sci-divider my-6"></div>
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
</template>

<script>

import SelectSearch from "../shared/select_search.vue";
import axios from '../../packs/custom_axios.js';

export default {
  name: "UserPreferences",
  props: {
    userSettings: Object,
    timeZones: Array,
    dateFormats: Array,
    updateUrl: String
  },
  data: function() {
    return {
      selectedTimeZone: null,
      selectedDateFormat: null
    };
  },
  created() {
    this.selectedTimeZone = this.userSettings.time_zone;
    this.selectedDateFormat = this.userSettings.date_format;
  },
  components: {
    SelectSearch,
    PerfectScrollbar
  },
  methods: {
    setTimeZone(value) {
      this.selectedTimeZone = value;
      axios.put(this.updateUrl, {
          user: { time_zone: value }
      })
    },
    setDateFormat(value) {
      this.selectedDateFormat = value;
      axios.put(this.updateUrl, {
          user: { date_format: value }
      })
    }
  },
}
</script>