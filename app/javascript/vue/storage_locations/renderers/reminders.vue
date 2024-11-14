<template>
  <div v-if="params.data.has_reminder">
    <GeneralDropdown ref="dropdown" position="right" @open="getReminders">
      <template v-slot:field>
        <i class="sn-icon sn-icon-notifications "></i>
      </template>
      <template v-slot:flyout>
        <ul v-if="reminders" v-html="reminders.html" class="list-none p-0 reminders-view-mode"></ul>
      </template>
    </GeneralDropdown>
  </div>
</template>

<script>
import axios from '../../../packs/custom_axios.js';
import GeneralDropdown from '../../shared/general_dropdown.vue';

export default {
  name: 'RemindersRenderer',
  props: {
    params: {
      required: true
    }
  },
  data() {
    return {
      reminders: null
    };
  },
  components: {
    GeneralDropdown
  },
  methods: {
    getReminders() {
      axios.get(this.params.data.reminders_url)
        .then((response) => {
          this.reminders = response.data;
        });
    }
  }
};
</script>
