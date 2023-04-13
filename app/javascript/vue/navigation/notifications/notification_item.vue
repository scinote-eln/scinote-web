<template>
  <div class="sci-navigation--notificaitons-flyout-notification">
    <div class="sci-navigation--notificaitons-flyout-notification-icon" :class="notification.type_of">
      <i class="fas" :class="icon"></i>
    </div>
    <div class="sci-navigation--notificaitons-flyout-notification-date">
      {{ notification.created_at }}
    </div>
    <div class="sci-navigation--notificaitons-flyout-notification-title">
      {{ notification.title }}
    </div>
    <div v-if="notification.type_of !== 'system'" v-html="notification.message" class="sci-navigation--notificaitons-flyout-notification-message"></div>
    <a v-else :href="notification.url" class="sci-navigation--notificaitons-flyout-notification-message">{{ i18n.t('nav.notifications.read_more') }}</a>
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
        case 'system':
          return 'fa-gift';
        case 'assignment':
          return 'fa-list-alt';
        case 'recent_changes':
          return 'fa-list-alt';
      }
    }
  }
}
</script>
