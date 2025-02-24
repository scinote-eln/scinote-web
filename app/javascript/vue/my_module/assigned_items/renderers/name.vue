<template>
  <div class="flex items-center gap-2">
    <GeneralDropdown v-if="params.data.hasActiveReminders">
      <template v-slot:field>
        <div @click="loadReminders" class="cursor-pointer flex h-6 rounded hover:bg-sn-super-light-grey">
          <i class="sn-icon sn-icon-notifications"></i>
        </div>
      </template>
      <template v-slot:flyout>
        <ul v-html="reminders" class="list-none pl-0"></ul>
      </template>
    </GeneralDropdown>
    <a class="hover:no-underline flex items-center gap-1 record-info-link"
      :title="params.data[0]"
      :href="params.data.recordInfoUrl"
    >
      <span class="truncate">
        {{ params.data[0] }}
      </span>
    </a>
  </div>
</template>

<script>
import axios from 'axios';
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
        });
    }
  }
};
</script>
