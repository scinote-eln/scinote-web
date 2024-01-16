<template>
  <span class="breadcrumbs-collapsed-container">
    <span
      class="cursor-pointer text-sn-blue flex flex-nowrap whitespace-nowrap items-center gap-1"
      data-toggle="dropdown"
      :title="i18n.t('projects.index.breadcrumbs_collapsed')"
      @click="open = !open"
    >
      •••
      <span class="caret"></span>
      <span class="delimiter">
        <img :src="delimiterUrl" alt="navigate next" class="navigate_next" />
      </span>
    </span>
    <perfect-scrollbar>
      <ul
        class="absolute top-11 left-0 w-56 max-h-36 flex flex-col items-stretch gap-2 overflow-auto
               bg-sn-white border border-sn-grey rounded-md shadow-md list-none p-2"
        :class="{ hidden: !open }"
      >
        <li v-for="item in items" :key="item.url">
          <a :href="item.url" class="breadcrumbs-item breadcrumb-link shortened" title="item.label">
            <span
              class="breadcrumbs-link shortened"
              >{{ item.label }}</span>
            <span class="delimiter">
              <img
                :src="delimiterUrl"
                alt="navigate next"
                class="navigate_next"
              />
            </span>
          </a>
        </li>
      </ul>
    </perfect-scrollbar>
  </span>
</template>

<script>
import { PerfectScrollbar } from 'vue3-perfect-scrollbar';

export default {
  name: 'BreadcrumbsDropdown',
  props: {
    items: Array,
    delimiterUrl: String
  },
  components: { PerfectScrollbar },
  data() {
    return {
      open: false
    };
  }
};
</script>
