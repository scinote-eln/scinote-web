<template>
  <div class="sci-navigation--notificaitons-flyout-notification">
    <div class="sci-navigation--notificaitons-flyout-notification-icon" :class="notification.type_of">
      <i class="fas" :class="icon"></i>
    </div>
    <div class="sci-navigation--notificaitons-flyout-notification-date">
      {{ notification.created_at }}
    </div>
    <div class="sci-navigation--notificaitons-flyout-notification-title"
         v-html="notification.title"
         :data-seen="notification.checked"></div>
    <div v-if="notification.type_of !== 'system_message'" v-html="notification.message" class="sci-navigation--notificaitons-flyout-notification-message"></div>
    <a v-else @click="showSystemNotification()" class="sci-navigation--notificaitons-flyout-notification-message" data-notification="system">{{ i18n.t('nav.notifications.read_more') }}</a>
  </div>
</template>

<script>
export default {
  name: 'NotificationItem',
  props: {
    notification: Object
  },
  computed: {
    icon() {
      switch(this.notification.type_of) {
        case 'deliver':
          return 'fa-truck';
        case 'system_message':
          return 'fa-gift';
        case 'assignment':
          return 'fa-list-alt';
        case 'recent_changes':
          return 'fa-list-alt';
      }
    }
  },
  methods: {
    showSystemNotification() {
      $.get(this.notification.action_url, (data) => {
        let systemNotificationModal = $('#manage-module-system-notification-modal');
        let systemNotificationModalBody = systemNotificationModal.find('.modal-body');
        let systemNotificationModalTitle = systemNotificationModal.find('#manage-module-system-notification-modal-label');
        systemNotificationModalBody.html(data.modal_body);
        systemNotificationModalTitle.text(data.modal_title);
        systemNotificationModal.modal('show');
      });
    }
  }
}
</script>
