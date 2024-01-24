<template>
  <div class="sci-navigation--notificaitons-flyout-notification">
    <div class="sci-navigation--notificaitons-flyout-notification-date">
      {{ notification.attributes.created_at }}
    </div>
    <div class="sci-navigation--notificaitons-flyout-notification-title"
         v-html="notification.attributes.title"
         :data-seen="notification.attributes.checked"></div>
    <div v-html="notification.attributes.message" class="sci-navigation--notificaitons-flyout-notification-message"></div>
    <div v-if="notification.attributes.breadcrumbs" class="flex items-center flex-wrap gap-0.5">
      <template v-for="(breadcrumb, index) in notification.attributes.breadcrumbs" :key="index">
        <div class="flex items-center gap-0.5">
          <i v-if="index > 0" class="sn-icon sn-icon-right"></i>
          <a :href="breadcrumb.url" :title="breadcrumb.name" class="truncate max-w-[20ch] inline-block">{{ breadcrumb.name }}</a>
        </div>
      </template>
    </div>
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
      switch (this.notification.attributes.type_of) {
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
};
</script>
