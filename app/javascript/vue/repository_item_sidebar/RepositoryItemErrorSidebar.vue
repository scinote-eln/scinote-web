<template>
  <transition enter-from-class="translate-x-full w-0"
              enter-active-class="transition-all ease-sharp duration-[588ms]"
              leave-active-class="transition-all ease-sharp duration-[588ms]"
              leave-to-class="translate-x-full w-0"
              v-click-outside="close">
    <div ref="wrapper" v-if="isShowing"
      class='items-sidebar-wrapper bg-white gap-2.5 self-stretch rounded-tl-4 rounded-bl-4 sn-shadow-menu-lg h-full w-[565px]'>

      <div class="w-full h-full pl-6 bg-white flex flex-col">
        <div class="sticky top-0 right-0 bg-white flex z-50 flex-col h-[78px] pt-6">
          <div class="header flex w-full h-[30px] pr-6">
            <i id="close-icon" @click="close"
              class="sn-icon sn-icon-close ml-auto cursor-pointer my-auto mx-0"></i>
          </div>
          <div id="divider" class="w-500 bg-sn-light-grey flex items-center self-stretch h-px mt-6 mr-6"></div>
        </div>
        <div class="flex flex-col flex-1 justify-center items-center gap-1">
          <i class="sn-icon sn-icon-alert-warning text-sn-alert-passion"></i>
          <span class="font-semibold leading-5">{{ i18n.t('repositories.item_card_errors.item_not_found') }}</span>
        </div>
      </div>
    </div>
  </transition>
</template>

<script>
import { vOnClickOutside } from '@vueuse/components';

export default {
  name: 'RepositoryItemErrorSidebar',
  directives: {
    'click-outside': vOnClickOutside
  },
  data() {
    return {
      isShowing: false
    };
  },
  mounted() {
    this.isShowing = true;
  },
  methods: {
    close() {
      this.$nextTick(() => {
        this.isShowing = false;
      });
    }
  }
};
</script>
