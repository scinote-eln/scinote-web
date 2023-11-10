<template>
  <div class="sci-navigation--notificaitons-flyout-notification">
    <div class="sci-navigation--notificaitons-flyout-notification-icon" :class="notification.type_of">
      <i :class="icon"></i>
    </div>
    <div class="sci-navigation--notificaitons-flyout-notification-date">
      {{ notification.created_at }}
    </div>
    <div class="sci-navigation--notificaitons-flyout-notification-title"
         v-html="notification.title"
         :data-seen="notification.checked"></div>
    <div v-html="notification.message" class="sci-navigation--notificaitons-flyout-notification-message"></div>
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
          return 'fas fa-truck';
        case 'assignment':
          return 'fas fa-list-alt';
        case 'recent_changes':
          return 'fas fa-list-alt';
        case 'deliver_error':
          return 'sn-icon sn-icon-alert-warning';
      }
    }
  }
}
</script>
