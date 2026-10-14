<template>
  <div v-if="params.value > 0">
    <GeneralDropdown>
      <template v-slot:field>
        <div class="relative flex items-center h-10 cursor-pointer" @click="loadReminders">
          <i class="sn-icon sn-icon-notifications"></i>
          <div class="absolute top-1 left-3 w-4 h-4 text-xs text-white bg-sn-science-blue rounded-full flex items-center justify-center">
            {{ this.params.value }}
          </div>
        </div>
      </template>
      <template v-slot:flyout>
        <ul class="list-none pl-0">
          <div class="reminder-list flex flex-col gap-4 m-3">
            <template v-for="(reminder, index) in reminders" :key="index">
              <li class="flex flex-col gap-1 row-reminders-notification">
                <template v-if="reminder.type == 'RepositoryStockValue'">
                  <div class="row-reminders-title">
                    <strong>{{ i18n.t('repository_row.reminder.low_stock_title') }}</strong>
                  </div>
                  <div class="row-reminders-body">
                    <template v-if="reminder.empty">
                      {{ i18n.t('repository_row.reminder.stock_empty') }}
                    </template>
                    <span v-else v-html="i18n.t('repository_row.reminder.stock_low_html', { stock_formated: reminder.stock_formatted })"></span>
                  </div>
                </template>
                <template v-else-if="reminder.type == 'RepositoryDateTimeValueBase'">
                  <div class="row-reminders-title">
                    <strong>{{ i18n.t('repository_row.reminder.date_reminder') }}</strong>
                  </div>
                  <div class="row-reminders-body">
                    <template v-if="reminder.expired">
                      {{ i18n.t('repository_row.reminder.item_expired') }}
                    </template>
                    <span v-else v-html="i18n.t('repository_row.reminder.date_expiration_html', { date_expiration: reminder.expiration_date_formatted })"></span>
                  </div>
                  <template v-if="reminder.message">
                    <div class="row-reminders-body">{{ reminder.message }}</div>
                  </template>
                </template>
                <div class="row-reminders-footer text-nowrap">
                  <button
                    v-if="reminder.clear_all_url"
                    class="btn btn-light btn-sm clear-reminders"
                    @click="clearReminders(reminder.clear_all_url)"
                    :tabindex="index + 1"
                  >
                    <i class="sn-icon sn-icon-close"></i>
                    {{ i18n.t('repository_row.reminder.clear_for_all') }}
                  </button>
                  <button
                    class="btn btn-light btn-sm clear-reminders"
                    @click="clearReminders(reminder.clear_url)"
                    :tabindex="index + 1"
                  >
                    <i class="sn-icon sn-icon-close"></i>
                    {{ i18n.t('repository_row.reminder.clear_for_me') }}
                  </button>
                </div>
              </li>
            </template>
          </div>
        </ul>
      </template>
    </GeneralDropdown>
  </div>
</template>

<script>

import axios from '../../../packs/custom_axios.js';
import GeneralDropdown from '../../shared/general_dropdown.vue';
import {
  active_reminder_repository_cells_repository_repository_row_path,
  repository_repository_row_path
 } from '../../../routes.js';

export default {
  props: {
    params: {
      type: Object,
      required: true
    }
  },
  computed: {
    rowRemindersUrl() {
      return active_reminder_repository_cells_repository_repository_row_path(
        this.params.data.repository_id,
        this.params.data.id
      );
    },
  },
  data() {
    return {
      reminders: []
    };
  },
  components: {
    GeneralDropdown
  },
  methods: {
    loadReminders() {
      axios.get(this.rowRemindersUrl)
        .then((response) => {
          this.reminders = response.data.reminders;

          this.params.dtComponent.$emit('updateRemindersCount', this.params.data, this.reminders.length);
        });
    },
    clearReminders(url) {
      axios.post(url)
        .then((response) => {
          this.loadReminders();
        });
    }
  }
};
</script>
