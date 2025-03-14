<template>
  <div class="sci--navigation--notificaitons-flyout" data-e2e="e2e-CO-notifications-flyout">
    <div class="sci--navigation--notificaitons-flyout-title" data-e2e="e2e-TX-notifications-title">
      {{ i18n.t('nav.notifications.title') }}
      <a
        class="ml-auto cursor-pointer text-sm font-normal"
        :href="this.preferencesUrl"
        :title="i18n.t('nav.settings')"
        data-e2e="e2e-BT-notifications-settings"
      >
        {{ i18n.t('nav.settings') }}
      </a>
    </div>
    <div class="flex items-center">
      <div
        @click="changeTab('all')"
        class="px-4 py-2 text-sn-grey cursor-pointer border-solid border-0 border-b-4 border-transparent"
        :class="{'!text-sn-black border-sn-blue': activeTab === 'all'}"
        data-e2e="e2e-BT-notifications-all-tab"
      >
        {{ i18n.t('nav.notifications.all') }}
      </div>
      <div
        @click="changeTab('unread')"
        class="px-4 py-2 text-sn-grey cursor-pointer border-solid border-0 border-b-4 border-transparent"
        :class="{'!text-sn-black border-sn-blue': activeTab === 'unread'}"
        data-e2e="e2e-BT-notifications-unread-tab"
      >
        {{ i18n.t('nav.notifications.unread') }}
      </div>
      <div
        @click="changeTab('read')"
        class="px-4 py-2 text-sn-grey cursor-pointer border-solid border-0 border-b-4 border-transparent"
        :class="{'!text-sn-black  border-sn-blue': activeTab === 'read'}"
        data-e2e="e2e-BT-notifications-read-tab"
      >
      {{ i18n.t('nav.notifications.read') }}
      </div>
      <div v-if="activeTab !== 'read'" class="py-2 ml-auto cursor-pointer" @click="markAllNotificationsAsRead" data-e2e="e2e-BT-notifications-readAll">
        {{ i18n.t('nav.notifications.read_all') }}
      </div>
    </div>
    <hr class="!mt-0.5">
    <perfect-scrollbar @wheel="preventPropagation" ref="scrollContainer" class="sci--navigation--notificaitons-flyout-notifications">
      <div class="sci-navigation--notificaitons-flyout-subtitle" v-if="todayNotifications.length" data-e2e="e2e-TX-notifications-today-subtitle">
        {{ i18n.t('nav.notifications.today') }}
      </div>
      <NotificationItem v-for="notification in todayNotifications" :key="notification.type_of + '-' + notification.id"
        @updateNotification="updateNotification"
        @close="$emit('close')"
        :notification="notification"
        :dataE2e="'notifications-today'"/>
      <div class="sci-navigation--notificaitons-flyout-subtitle" v-if="olderNotifications.length" data-e2e="e2e-TX-notifications-older-subtitle">
        {{ i18n.t('nav.notifications.older') }}
      </div>
      <NotificationItem v-for="notification in olderNotifications" :key="notification.type_of + '-' + notification.id"
        @updateNotification="updateNotification"
        @close="$emit('close')"
        :notification="notification"
        :dataE2e="'notifications-older'"/>
      <div class="next-page-loader">
        <img src="/images/medium/loading.svg" v-if="loadingPage" />
      </div>
    </perfect-scrollbar>
  </div>
</template>

<script>

import NotificationItem from './notification_item.vue';
import axios from '../../../packs/custom_axios.js';

export default {
  name: 'NotificationsFlyout',
  components: {
    NotificationItem
  },
  props: {
    notificationsUrl: String,
    markAllNotificationsUrl: String,
    unseenNotificationsCount: Number,
    preferencesUrl: String
  },
  data() {
    return {
      notifications: [],
      nextPageUrl: null,
      scrollBar: null,
      activeTab: 'all',
      loadingPage: false,
      firstPageUrl: null
    };
  },
  created() {
    this.nextPageUrl = this.notificationsUrl;
    this.firstPageUrl = this.notificationsUrl;
    this.loadNotifications();
  },
  mounted() {
    const container = this.$refs.scrollContainer.$el;

    container.addEventListener('ps-scroll-y', (e) => {
      if (e.target.scrollTop + e.target.clientHeight >= e.target.scrollHeight - 20) {
        this.loadNotifications();
      }
    });
  },
  beforeUnmount() {
    document.body.style.overflow = 'auto';
  },
  computed: {
    filteredNotifications() {
      this.loadNotifications();
    },
    todayNotifications() {
      return this.notifications.filter((n) => n.attributes.today);
    },
    olderNotifications() {
      return this.notifications.filter((n) => !n.attributes.today);
    }
  },
  methods: {
    changeTab(tab) {
      this.activeTab = tab;
      this.notifications = [];
      this.nextPageUrl = this.firstPageUrl;
      this.loadNotifications();
    },
    markAllNotificationsAsRead() {
      axios.post(this.markAllNotificationsUrl)
        .then(() => {
          this.notifications = this.notifications.map((n) => {
            n.attributes.checked = true;
            return n;
          });
          this.$emit('update:unseenNotificationsCount');
        });
    },
    updateNotification(notification) {
      const index = this.notifications.findIndex((n) => n.id === notification.id);
      this.notifications.splice(index, 1, notification);
      this.$emit('update:unseenNotificationsCount');
    },
    preventPropagation(e) {
      e.stopPropagation();
      e.preventDefault();
    },
    loadNotifications() {
      if (this.nextPageUrl == null || this.loadingPage) return;

      this.loadingPage = true;

      axios.get(this.nextPageUrl, { params: { tab: this.activeTab } })
        .then((response) => {
          this.notifications = this.notifications.concat(response.data.data);
          this.nextPageUrl = response.data.links.next;
          this.loadingPage = false;
          this.$emit('update:unseenNotificationsCount');
        })
        .catch((error) => {
          this.loadingPage = false;
        });
    }
  }
};
</script>
