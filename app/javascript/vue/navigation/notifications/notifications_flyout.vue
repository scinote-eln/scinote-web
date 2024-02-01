<template>
  <div class="sci--navigation--notificaitons-flyout">
    <div class="sci--navigation--notificaitons-flyout-title">
      {{ i18n.t('nav.notifications.title') }}
      <a class="ml-auto cursor-pointer text-sm font-normal" :href="this.preferencesUrl" :title="i18n.t('nav.settings')">
        {{ i18n.t('nav.settings') }}
      </a>
    </div>
    <hr>
    <perfect-scrollbar @wheel="preventPropagation" ref="scrollContainer" class="sci--navigation--notificaitons-flyout-notifications">
      <div class="sci-navigation--notificaitons-flyout-subtitle" v-if="todayNotifications.length">
        {{ i18n.t('nav.notifications.today') }}
      </div>
      <NotificationItem v-for="notification in todayNotifications" :key="notification.type_of + '-' + notification.id"
        :notification="notification" />
      <div class="sci-navigation--notificaitons-flyout-subtitle" v-if="olderNotifications.length">
        {{ i18n.t('nav.notifications.older') }}
      </div>
      <NotificationItem v-for="notification in olderNotifications" :key="notification.type_of + '-' + notification.id"
        :notification="notification" />
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
    unseenNotificationsCount: Number,
    preferencesUrl: String
  },
  data() {
    return {
      notifications: [],
      nextPageUrl: null,
      scrollBar: null,
      loadingPage: false
    };
  },
  created() {
    this.nextPageUrl = this.notificationsUrl;
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
    preventPropagation(e) {
      e.stopPropagation();
      e.preventDefault();
    },
    loadNotifications() {
      if (this.nextPageUrl == null || this.loadingPage) return;

      this.loadingPage = true;

      axios.get(this.nextPageUrl)
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
