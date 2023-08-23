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
          return 'fa-truck';
        case 'assignment':
          return 'fa-list-alt';
        case 'recent_changes':
          return 'fa-list-alt';
      }
    }
  }
}
</script>
