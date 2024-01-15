<template>
  <div class="relative" v-if="listItems.length > 0" v-click-outside="closeMenuAndEmit">
    <button
      ref="openBtn"
      :class="btnClasses"
      :title="showMenu ? '' : title"
      @click="showMenu = !showMenu"
    >
      <i v-if="btnIcon" :class="btnIcon"></i>
      {{ btnText }}
      <i v-if="caret && showMenu" class="sn-icon sn-icon-up"></i>
      <i v-else-if="caret" class="sn-icon sn-icon-down"></i>
    </button>
    <div ref="flyout"
         class="absolute z-[150] bg-sn-white rounded p-2.5 sn-shadow-menu-sm min-w-full flex flex-col gap-[1px]"
         :class="{
            'right-0': position === 'right',
            'left-0': position === 'left',
            'bottom-0': openUp,
            '!mb-0': !openUp,
         }"
         v-if="showMenu"
    >
      <span v-for="(item, i) in listItems" :key="i" class="contents">
        <div v-if="item.dividerBefore" class="border-0 border-t border-solid border-sn-light-grey"></div>
        <a :href="item.url" v-if="!item.submenu"
          :target="item.url_target || '_self'"
          :class="{ 'bg-sn-super-light-blue': item.active }"
          :data-toggle="item.modalTarget && 'modal'"
          :data-target="item.modalTarget"
          class="block whitespace-nowrap rounded px-3 py-2.5 hover:!text-sn-blue hover:no-underline cursor-pointer hover:bg-sn-super-light-grey"
          @click="handleClick($event, item)"
        >
          {{ item.text }}
        </a>
        <div v-else class="-mx-2.5 px-2.5 group relative">
          <span
            :class="{ 'bg-sn-super-light-blue': item.active }"
            class="flex group items-center rounded relative text-sn-blue whitespace-nowrap px-3 py-2.5 hover:no-underline cursor-pointer group-hover:bg-sn-super-light-blue hover:!bg-sn-super-light-grey"
          >
            {{ item.text }}
            <i class="sn-icon sn-icon-right ml-auto"></i>
          </span>
          <div
              class="absolute bg-sn-white rounded p-2.5 sn-shadow-menu-sm  flex flex-col gap-[1px] tw-hidden group-hover:block"
              :class="{
                'left-0 ml-[100%]': item.position === 'right',
                'right-0 mr-[100%]': item.position === 'left',
                'bottom-0': openUp,
                'top-0': !openUp,
              }"
          >
            <a v-for="(sub_item, si) in item.submenu" :key="si"
              :href="sub_item.url"
              :traget="sub_item.url_target || '_self'"
              :class="{ 'bg-sn-super-light-blue': item.active }"
              class="block whitespace-nowrap rounded px-3 py-2.5 hover:!text-sn-blue hover:no-underline cursor-pointer hover:bg-sn-super-light-grey"
              @click="handleClick($event, sub_item)"
            >
              {{ sub_item.text }}
            </a>
          </div>
        </div>
      </span>
    </div>
  </div>
</template>

<script>

import { vOnClickOutside } from '@vueuse/components';
import isInViewPort from './isInViewPort.js';

export default {
  name: 'DropdownMenu',
  props: {
    listItems: { type: Array, default: () => [] },
    position: { type: String, default: 'left' },
    btnClasses: { type: String, default: 'btn btn-light' },
    btnText: { type: String, required: false },
    btnIcon: { type: String, required: false },
    caret: { type: Boolean, default: false }
  },
  data() {
    return {
      showMenu: false,
      openUp: false
    };
  },
  directives: {
    'click-outside': vOnClickOutside
  },
  watch: {
    showMenu(newValue) {
      if (newValue) {
        this.$emit('menu-visibility-changed', newValue);
      }

      if (this.showMenu) {
        this.openUp = false;
        this.$nextTick(() => {
          this.$refs.flyout.style.marginBottom = `${this.$refs.openBtn.offsetHeight}px`;
          this.updateOpenDirectoin();
        });
      }
    }
  },
  mounted() {
    document.addEventListener('scroll', this.updateOpenDirectoin);
  },
  unmounted() {
    document.removeEventListener('scroll', this.updateOpenDirectoin);
  },
  methods: {
    closeMenu() {
      this.showMenu = false;
    },
    closeMenuAndEmit(event) {
      const isClickInsideModal = event.target.closest('.modal');

      if (!isClickInsideModal) {
        this.showMenu = false;
        this.$emit('menu-visibility-changed', false);
      }
    },
    handleClick(event, item) {
      if (!item.url) {
        event.preventDefault();
      }

      if (item.emit) {
        this.$emit(item.emit, item.params);
      }

      this.closeMenu();
    },
    updateOpenDirectoin() {
      if (!this.showMenu) return;

      this.openUp = false;
      this.$nextTick(() => {
        this.openUp = !isInViewPort(this.$refs.flyout);
      });
    }
  }
};
</script>
