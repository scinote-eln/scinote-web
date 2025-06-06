<template>
  <div ref="scrollContainer" class="h-full overflow-y-auto">
    <div v-if="favorites.length > 0" v-for="favorite in favorites" class="px-4 hover:bg-sn-super-light-grey">
      <a :href="favorite.attributes.url" class="flex text-black items-center gap-2 py-0.5 hover:no-underline hover:text-black ">
        <i class="sn-icon sn-icon-star-filled  text-sn-alert-brittlebush" style="font-size: 32px !important"></i>
        <div class="overflow-hidden">
          <div class="flex items-center gap-2 text-sn-grey">
            <template v-for="(breadcrumb, index) in favorite.attributes.breadcrumbs" :key="index" >
              <div v-if="index > 0">
                <span v-if="index > 1"> / </span>
                <span v-if="index + 1 < favorite.attributes.breadcrumbs.length" class="text-xs">
                  {{ breadcrumb.name }}
                </span>
                <span v-else class="text-xs">
                  {{ favorite.attributes.code }}
                </span>
              </div>
            </template>
          </div>
          <div :title="favorite.attributes.name" class="font-bold text-sn-dark-grey text-base truncate h-7">{{ favorite.attributes.name }}</div>
        </div>
        <div
          class="ml-auto rounded px-1.5 py-1 mt-4 shrink-0 text-xs font-bold"
          :class="{
            'text-black border': favorite.attributes.status.light_color,
            'text-white': !favorite.attributes.status.light_color,
          }"
          :style="{ backgroundColor: favorite.attributes.status.color }"
        >
          {{ favorite.attributes.status.name }}
        </div>
      </a>
      <hr class="my-0">
    </div>
    <h1 v-else-if="!loading" class="ml-6">
      {{ i18n.t('dashboard.current_tasks.no_tasks.favorites') }}
    </h1>
  </div>
</template>

<script>
import axios from '../../packs/custom_axios.js';

export default {
  name: 'FavoritesWidget',
  props: {
    favoritesUrl: {
      type: String,
      required: true
    }
  },
  data() {
    return {
      favorites: [],
      page: 1,
      loading: true
    };
  },
  mounted() {
    const activeTab = document.querySelector('.current-tasks-navbar .navbar-link.active');
    if (activeTab.dataset.mode === 'favorites') {
      this.resetFavorites();
    }

    this.$refs.scrollContainer.addEventListener('scroll', () => {
      if (this.$refs.scrollContainer.scrollTop + this.$refs.scrollContainer.clientHeight >= this.$refs.scrollContainer.scrollHeight - 100) {
        this.loadFavorites();
      }
    });
  },
  methods: {
    resetFavorites() {
      this.favorites = [];
      this.page = 1;
      this.loading = false;
      this.loadFavorites();
    },
    loadFavorites() {
      if (this.loading || !this.page) return;

      this.loading = true;
      axios.get(this.favoritesUrl, { params: { page: this.page } })
        .then((response) => {
          this.favorites = this.favorites.concat(response.data.data);
          if (response.data.data.length > 0) {
            this.page += 1;
          } else {
            this.page = null;
          }
          this.loading = false;
        });
    }
  }
};
</script>
