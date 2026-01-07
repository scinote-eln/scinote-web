<template>
  <div :title="message" :class="divClass">
    <i :class="iconClass"></i>
    <span class="truncate">{{message}}</span>
  </div>
</template>

<script>
export default {
  props: {
    params: {
      type: Object,
      required: true
    }
  },
  data() {
    return {
      message: null,
      icon: null,
      color: null
    }
  },
  computed: {
    divClass() {
      return `flex items-center gap-2.5 ${this.color}`;
    },
    iconClass() {
      return `sn-icon sn-icon-${this.icon}`;
    }
  },
  created() {
    const { import_status: importStatus, import_message: importMessage } = this.params.data;

    if (importStatus === 'created' || importStatus === 'updated') {
      this.message = this.i18n.t(`repositories.import_records.steps.step3.status_message.${importStatus}`);
      this.color = 'text-sn-alert-green';
      this.icon = 'check';
    } else if (importStatus === 'unchanged' || importStatus === 'archived') {
      this.message = this.i18n.t(`repositories.import_records.steps.step3.status_message.${importStatus}`);
      this.icon = 'hamburger';
    } else if (importStatus === 'duplicated' || importStatus === 'invalid') {
      this.message = this.i18n.t(`repositories.import_records.steps.step3.status_message.${importStatus}`);
      this.color = 'text-sn-alert-passion';
      this.icon = 'close';
    }

    if (importMessage) {
      this.message = importMessage;
    }
  }
};
</script>
