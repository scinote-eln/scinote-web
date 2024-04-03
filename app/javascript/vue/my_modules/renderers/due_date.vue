<template>
  <div class="flex relative items-center gap-2">
    <DateTimePicker
      v-if="this.params.data.urls.update_due_date"
      :defaultValue="dueDate"
      @change="updateDueDate"
      mode="datetime"
      :placeholder="i18n.t('my_modules.details.no_due_date_placeholder')"
      :customIcon="customIcon"
      :clearable="true"/>
    <template v-else-if="params.data.due_date_formatted ">
      <i :class="customIcon || 'sn-icon sn-icon-calendar'"></i>
      {{ params.data.due_date_formatted }}
    </template>
    <template v-else>
      {{ i18n.t('my_modules.details.no_due_date') }}
    </template>
  </div>
</template>

<script>

import axios from '../../../packs/custom_axios.js';
import DateTimePicker from '../../shared/date_time_picker.vue';

export default {
  name: 'DueDateRenderer',
  components: {
    DateTimePicker
  },
  props: {
    params: {
      required: true
    }
  },
  data() {
    return {
      dueDate: null
    };
  },
  created() {
    this.dueDate = new Date(this.params.data.due_date?.replace(/([^!\s])-/g, '$1/'));
  },
  computed: {
    customIcon() {
      if (this.params.data.due_date_status === 'overdue') {
        return 'sn-icon sn-icon-alert-warning text-sn-delete-red';
      }

      if (this.params.data.due_date_status === 'one_day_prior') {
        return 'sn-icon sn-icon-alert-warning text-sn-alert-brittlebush';
      }

      return null;
    }
  },
  methods: {
    updateDueDate(value) {
      this.dueDate = value;
      axios.put(this.params.data.urls.update_due_date, {
        my_module: {
          due_date: this.formatDate(value)
        }
      }).then(() => {
        this.params.dtComponent.updateTable();
      });
    },
    formatDate(date) {
      if (!(date instanceof Date)) return null;

      const y = date.getFullYear();
      const m = date.getMonth() + 1;
      const d = date.getDate();
      const hours = date.getHours();
      const mins = date.getMinutes();
      return `${y}/${m}/${d} ${hours}:${mins}`;
    }
  }
};
</script>
