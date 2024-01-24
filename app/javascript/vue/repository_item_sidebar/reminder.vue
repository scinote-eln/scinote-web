<template v-if="value?.reminder === true">
  <div class="inline-block float-right cursor-pointer relative" :title="reminderTitle"
     tabindex='-1'>
    <i class="sn-icon sn-icon-notifications row-reminders-icon"></i>
    <span :class="`inline-block absolute rounded-full w-2 h-2 right-1 top-0.5 ${reminderColor}`"></span>
  </div>
</template>

<script>
export default {
  name: 'Reminder',
  props: {
    value: null
  },
  computed: {
    reminderColor() {
      if (this.value?.reminder && (this.value?.stock_amount > 0 || this.value?.days_left > 0)) {
        return 'bg-sn-alert-brittlebush';
      }
      return 'bg-sn-alert-passion';
    },
    reminderTitle() {
      let title = this.value?.reminder_text;
      if (this.value?.reminder_message) title = `${title}\n${this.value?.reminder_message}`;

      return title;
    }
  }
};
</script>
