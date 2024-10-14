<template>
  <div class="sci-navigation--notificaitons-flyout-notification">
    <div class="flex item-center">
      <div class="sci-navigation--notificaitons-flyout-notification-date">
        {{ notification.attributes.created_at }}
      </div>
      <div class="ml-auto cursor-pointer" @click="toggleRead()">
        <div v-if="!notification.attributes.checked" class="w-2.5 h-2.5 bg-sn-coral rounded-full cursor-pointer"></div>
        <div v-else class="w-2.5 h-2.5 border-2 border-sn-grey rounded-full border-solid cursor-pointer"></div>
      </div>
    </div>
    <a :href="lastBreadcrumbUrl" @click="toggleRead(true)" class="hover:no-underline text-black hover:text-black">
      <div class="sci-navigation--notificaitons-flyout-notification-title"
          v-html="notification.attributes.title"
          :data-seen="notification.attributes.checked"></div>
      <div v-html="notification.attributes.message" class="sci-navigation--notificaitons-flyout-notification-message"></div>
    </a>
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
import axios from '../../../packs/custom_axios.js';

export default {
  name: 'NotificationItem',
  props: {
    notification: Object
  },
  computed: {
    lastBreadcrumbUrl() {
      if (!this.notification.attributes.breadcrumbs) {
        return null;
      }
      return this.notification.attributes.breadcrumbs[this.notification.attributes.breadcrumbs.length - 1]?.url;
    }
  },
  methods: {
    toggleRead(check = false) {
      const params = {};
      if (!this.notification.attributes.checked || check) {
        params.mark_as_read = true;
      }

      axios.post(this.notification.attributes.toggle_read_url, params)
        .then((response) => {
          const notification = response.data.data;
          this.$emit('updateNotification', notification);
        });
    }
  }
};
</script>
