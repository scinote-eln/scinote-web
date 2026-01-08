<template>
  <div class="flex items-center gap-2">
    <GeneralDropdown v-if="params.data.has_active_reminders">
      <template v-slot:field>
        <div @click="loadReminders" class="cursor-pointer flex h-6 rounded hover:bg-sn-super-light-grey">
          <i class="sn-icon sn-icon-notifications"></i>
        </div>
      </template>
      <template v-slot:flyout>
        <ul ref="reminders" v-html="reminders" class="list-none pl-0"></ul>
      </template>
    </GeneralDropdown>
    <a v-if="params.data.name"
      class="hover:no-underline record-info-link truncate block cursror-pointer"
      :title="params.data.name"
      :href="recordInfoUrl"
    >
      {{ params.data.name }}
    </a>
    <span v-else
      :title="i18n.t('my_modules.assigned_items.repository.private_repository_row_name', {repository_row_code: params.data.code })"
      class="text-sn-grey truncate"
    >
      <i class="sn-icon sn-icon-locked-task"></i>
      {{ i18n.t('my_modules.assigned_items.repository.private_repository_row_name', {repository_row_code: params.data.code }) }}
    </span>
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
    recordInfoUrl() {
      return repository_repository_row_path(
        this.params.data.repository_id,
        this.params.data.id
      );
    }
  },
  components: {
    GeneralDropdown
  },
  data() {
    return {
      reminders: null
    };
  },
  methods: {
    loadReminders() {
      axios.get(this.rowRemindersUrl)
        .then((response) => {
          this.reminders = response.data.html;
          this.$nextTick(() => {
            this.$refs.reminders.querySelectorAll('.clear-reminders').forEach((reminder) => {
              reminder.addEventListener('click', (e) => {
                const element = e.currentTarget;
                const url = element.dataset.rowHideRemindersUrl;
                axios.post(url)
                  .then(() => {
                    this.reminders = null;
                  });
              });
            });
          });
        });
    }
  }
};
</script>
