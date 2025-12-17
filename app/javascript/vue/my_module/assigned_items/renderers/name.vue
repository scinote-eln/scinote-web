<template>
  <div class="flex items-center gap-2">
    <GeneralDropdown v-if="params.data.hasActiveReminders">
      <template v-slot:field>
        <div @click="loadReminders" class="cursor-pointer flex h-6 rounded hover:bg-sn-super-light-grey">
          <i class="sn-icon sn-icon-notifications"></i>
        </div>
      </template>
      <template v-slot:flyout>
        <ul ref="reminders" v-html="reminders" class="list-none pl-0"></ul>
      </template>
    </GeneralDropdown>
    <a v-if="params.data.recordInfoUrl"
      class="hover:no-underline record-info-link truncate block"
      :title="params.data[0]"
      :href="params.data.recordInfoUrl"
    >
      {{ params.data[0] }}
    </a>
    <span v-else
      :title="i18n.t('my_modules.assigned_items.repository.private_repository_row_name', {repository_row_code: params.data.code })"
      class="text-sn-grey truncate"
    >
      <i class="sn-icon sn-icon-locked-task"></i>
      {{ i18n.t('my_modules.assigned_items.repository.private_repository_row_name', {repository_row_code: params.data.code }) }}
    </span>

    <template v-if="params.data.DT_RowAttr" v-for="state in params.data.DT_RowAttr['data-state']" :key="state">
      <i v-if="state == 'archived'" class="sn-icon sn-icon-archive text-sn-grey" :title="i18n.t('general.archived')"></i>
      <span v-else class="text-sn-grey bg-sn-light-grey text-xs px-1.5 py-1 ">
        {{ state }}
      </span>
    </template>
  </div>
</template>

<script>

import axios from '../../../../packs/custom_axios.js';
import GeneralDropdown from '../../../shared/general_dropdown.vue';

export default {
  props: {
    params: {
      type: Object,
      required: true
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
      axios.get(this.params.data.rowRemindersUrl)
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
                    this.params.dtComponent.getRows();
                  });
              });
            });
          });
        });
    }
  }
};
</script>
