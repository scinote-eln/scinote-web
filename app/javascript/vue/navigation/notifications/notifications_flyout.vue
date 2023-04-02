<template>
  <div class="sci--navigation--notificaitons-flyout">
    <div class="sci--navigation--notificaitons-flyout-title">
      {{ i18n.t('nav.notifications.title') }}
      <i class="fas fa-times" @click="$emit('close')"></i>
    </div>
    <div class="sci--navigation--notificaitons-flyout-tabs">
      <div class="sci--navigation--notificaitons-flyout-tab"
           @click="activeTab = 'all'"
           :class="{'active': activeTab == 'all'}">
        {{ i18n.t('nav.notifications.all') }}
      </div>
      <div class="sci--navigation--notificaitons-flyout-tab"
           @click="activeTab = 'message'"
           :class="{'active': activeTab == 'message'}">
        {{ i18n.t('nav.notifications.message') }}
      </div>
      <div class="sci--navigation--notificaitons-flyout-tab"
           @click="activeTab = 'system'"
           :class="{'active': activeTab == 'system'}">
        {{ i18n.t('nav.notifications.system') }}
      </div>
    </div>
    <hr>
    <div class="sci--navigation--notificaitons-flyout-notifications">
      <div class="sci-navigation--notificaitons-flyout-subtitle" v-if="todayNotifications.length" >
        {{ i18n.t('nav.notifications.today') }}
      </div>
      <NotificationItem v-for="notification in todayNotifications" :key="notification.id" :notification="notification" />
      <div class="sci-navigation--notificaitons-flyout-subtitle" v-if="olderNotifications.length" >
        {{ i18n.t('nav.notifications.older') }}
      </div>
      <NotificationItem v-for="notification in olderNotifications" :key="notification.id" :notification="notification" />
    </div>
  </div>
</template>

<script>

import NotificationItem from './notification_item.vue'

export default {
  name: 'NotificationsFlyout',
  components: {
    NotificationItem
  },
  props: {
    notificationsUrl: String
  },
  data() {
    return {
      notifications: [],
      activeTab: 'all',
      nextPage: 2
    }
  },
  mounted() {
    // fake notifications
    this.notifications = [
      { id: 'N1', type_of: 'assignment', title: 'Project assigned', created_at: new Date(), message: "Project:  <a href=\"/projects/1\">test</a>" },
      { id: 'SN1', type_of: 'system', title: 'New Scinote Version', created_at: new Date(), url: '/system_notificiatons' },
      { id: 'N2',type_of: 'deliver', title: 'New report', created_at: (new Date('2022-12-17T03:24:00')), message: "Report:  <a href=\"/reports/1\">test</a>" }
    ]
  },
  computed: {
    filteredNotifications() {
      switch(this.activeTab) {
        case 'all':
          return this.notifications;
        case 'system':
          return this.notifications.filter(n => n.type_of === 'system');
        case 'message':
          return this.notifications.filter(n => n.type_of !== 'system');
      }
    },
    todayNotifications() {
      let startOfDay = (new Date()).setUTCHours(0, 0, 0, 0);
      return this.filteredNotifications.filter(n => n.created_at >= startOfDay);
    },
    olderNotifications() {
      let startOfDay = (new Date()).setUTCHours(0, 0, 0, 0);
      return this.filteredNotifications.filter(n => n.created_at < startOfDay);
    }
  }
}
</script>
