<template>
  <div class="sci--navigation--notificaitons-flyout">
    <div class="sci--navigation--notificaitons-flyout-title">
      {{ i18n.t('nav.notifications.title') }}
      <i class="fas fa-times" @click="$emit('close')"></i>
    </div>
    <div class="sci--navigation--notificaitons-flyout-tabs">
      <div class="sci--navigation--notificaitons-flyout-tab"
           :data-unseen="unseenNotificationsCount"
           @click="setActiveTab('all')"
           :class="{'active': activeTab == 'all', 'has-unseen': unseenNotificationsCount > 0}">
        {{ i18n.t('nav.notifications.all') }}
      </div>
      <div class="sci--navigation--notificaitons-flyout-tab"
           @click="setActiveTab('message')"
           :class="{'active': activeTab == 'message'}">
        {{ i18n.t('nav.notifications.message') }}
      </div>
      <div class="sci--navigation--notificaitons-flyout-tab"
           @click="setActiveTab('system')"
           :class="{'active': activeTab == 'system'}">
        {{ i18n.t('nav.notifications.system') }}
      </div>
    </div>
    <hr>
    <perfect-scrollbar ref="scrollContainer" class="sci--navigation--notificaitons-flyout-notifications">
      <div class="sci-navigation--notificaitons-flyout-subtitle" v-if="todayNotifications.length" >
        {{ i18n.t('nav.notifications.today') }}
      </div>
      <NotificationItem v-for="notification in todayNotifications" :key="notification.type_of + '-' + notification.id" :notification="notification" />
      <div class="sci-navigation--notificaitons-flyout-subtitle" v-if="olderNotifications.length" >
        {{ i18n.t('nav.notifications.older') }}
      </div>
      <NotificationItem v-for="notification in olderNotifications" :key="notification.type_of + '-' + notification.id" :notification="notification" />
      <div class="next-page-loader">
        <img src="/images/medium/loading.svg" v-if="loadingPage"/>
      </div>
    </perfect-scrollbar>
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
    notificationsUrl: String,
    unseenNotificationsCount: Number
  },
  data() {
    return {
      notifications: [],
      activeTab: 'all',
      nextPage: 1,
      scrollBar: null,
      loadingPage: false
    }
  },
  created() {
    this.loadNotifications();
  },
  mounted() {
    let container = this.$refs.scrollContainer.$el
    container.addEventListener('ps-y-reach-end', (e) => {
      this.loadNotifications();
    })
  },
  computed: {
    filteredNotifications() {
      this.loadNotifications();
    },
    todayNotifications() {
      let startOfDay = (new Date()).setUTCHours(0, 0, 0, 0);
      return this.notifications.filter(n => moment(n.created_at) >= startOfDay);
    },
    olderNotifications() {
      let startOfDay = (new Date()).setUTCHours(0, 0, 0, 0);
      return this.notifications.filter(n => moment(n.created_at) < startOfDay);
    }
  },
  methods: {
    setActiveTab(selection) {
      this.activeTab = selection;
      this.nextPage = 1;
      this.notifications = [];
      this.loadNotifications();
    },
    loadNotifications() {
      if (this.nextPage == null || this.loadingPage) return;

      this.loadingPage = true;
      $.getJSON(this.notificationsUrl, { type: this.activeTab, page: this.nextPage }, (result) => {
        this.notifications = this.notifications.concat(result.notifications);
        this.nextPage = result.next_page;
        this.loadingPage = false;
      });
    }
  }
}
</script>
