<template v-if="value.reminder === true">
  <div class="inline-block float-right cursor-pointer relative" data-placement="top" data-toggle="tooltip" :title="reminderAttrs.text"
     tabindex='-1'>
    <i class="sn-icon sn-icon-notifications row-reminders-icon"></i>
    <span :class="`inline-block absolute rounded-full w-2 h-2 right-1 top-0.5 ${reminderAttrs.color}`"></span>
  </div>
</template>

<script>
  export default {
    name: 'Reminder',
    props: {
      valueType: null,
      value: null,
    },
    computed: {
      reminderAttrs() {
        let data = {}
        switch (true) {
          case this.valueType === 'RepositoryStockValue':
            if (this.value.stock_amount > 0) {
              data['color'] = 'bg-sn-alert-brittlebush';
              data['text'] =  I18n.t('repositories.item_card.reminders.stock_low', { stock_formated: this.value.stock_formatted });
            } else {
              data['color'] = 'bg-sn-alert-passion';
              data['text'] = I18n.t('repositories.item_card.reminders.stock_empty');
            }
            break;
          case ['RepositoryDateTimeValue', 'RepositoryDateValue'].includes(this.valueType):
            if (new Date(this.value.datetime).getTime() >= new Date().getTime()) {
              const daysLeft = Math.ceil((new Date(this.value.datetime).getTime() - new Date().getTime())/86400000)
              const dateExpiration = `${daysLeft} ${I18n.t(`repositories.item_card.reminders.day.${daysLeft === 1 ? 'one' : 'other'}`)}`
              data['color'] = 'bg-sn-alert-brittlebush';
              data['text'] = `${I18n.t('repositories.item_card.reminders.date_expiration', { date_expiration: dateExpiration })}\n${this.value.reminder_message}`;
            } else {
              data['color'] = 'bg-sn-alert-passion';
              data['text'] = `${I18n.t('repositories.item_card.reminders.item_expired')}\n${this.value.reminder_message}`;
            }
            break;
          default:
            break;
        }
        return data
      }
    }
  }
</script>
