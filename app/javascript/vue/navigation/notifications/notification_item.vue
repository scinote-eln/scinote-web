<template>
  <div class="sci-navigation--notificaitons-flyout-notification hover:bg-sn-super-light-grey !px-2 !-mx-2" :data-e2e="`e2e-CO-${dataE2e}-${notification.id}`">
    <div class="flex item-center">
      <a :href="lastBreadcrumbUrl" @click="toggleRead(true); closeFlyout()" class="hover:no-underline text-black hover:text-black grow">
        <div class="sci-navigation--notificaitons-flyout-notification-date" :data-e2e="`e2e-TX-${dataE2e}-${notification.id}-timestamp`">
          {{ notification.attributes.created_at }}
        </div>
      </a>
      <div class="ml-auto cursor-pointer" @click="toggleRead()" :data-e2e="`e2e-IC-${dataE2e}-${notification.id}-status`">
        <div v-if="!notification.attributes.checked" class="w-2.5 h-2.5 bg-sn-coral rounded-full cursor-pointer"></div>
        <div v-else class="w-2.5 h-2.5 border-2 border-sn-grey rounded-full border-solid cursor-pointer hover:border-sn-coral"></div>
      </div>
    </div>
    <a :href="lastBreadcrumbUrl" @click="toggleRead(true); closeFlyout()" class="hover:no-underline text-black hover:text-black">
      <div class="sci-navigation--notificaitons-flyout-notification-title"
          v-html="notification.attributes.title"
          :data-seen="notification.attributes.checked"
          :data-e2e="`e2e-TX-${dataE2e}-${notification.id}-title`"
      ></div>
      <div
        v-html="notification.attributes.message"
        class="sci-navigation--notificaitons-flyout-notification-message"
        :data-e2e="`e2e-TX-${dataE2e}-${notification.id}-message`"
      ></div>
    </a>
    <div v-if="notification.attributes.breadcrumbs" class="flex items-center flex-wrap gap-0.5" :data-e2e="`e2e-BC-${dataE2e}-${notification.id}-breadcrumbs`">
      <Breadcrumbs :breadcrumbs="notification.attributes.breadcrumbs" />
    </div>
  </div>
</template>

<script>
import axios from '../../../packs/custom_axios.js';
import Breadcrumbs from '../../shared/breadcrumbs.vue';

export default {
  name: 'NotificationItem',
  props: {
    notification: Object,
    dataE2e: { type: String, default: '' }
  },
  components: {
    Breadcrumbs
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
    closeFlyout() {
      this.$emit('close');
    },
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
