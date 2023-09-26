<template>
  <div class="relative" v-if="listItems.length > 0" >
    <button ref="openBtn" :class="btnClasses" @click="showMenu = !showMenu">
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
         v-click-outside="{handler: 'closeMenu', exclude: ['openBtn', 'flyout']}">
      <span v-for="(item, i) in listItems" :key="i" class="contents">
        <div v-if="item.dividerBefore" class="border-0 border-t border-solid border-sn-light-grey"></div>
        <a :href="item.url" v-if="!item.submenu"
          :traget="item.url_target || '_self'"
          :class="{ 'bg-sn-super-light-blue': item.active }"
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

export default {
  name: 'DropdownMenu',
  props: {
    listItems: { type: Array, default: () => [] },
    position: { type: String, default: 'left' },
    btnClasses: { type: String, default: 'btn btn-light' },
    btnText: { type: String, required: false },
    btnIcon: { type: String, required: false },
    caret: { type: Boolean, default: false },
  },
  data() {
    return {
      showMenu: false,
      openUp: false
    }
  },
  watch: {
    showMenu() {
      if (this.showMenu) {
        this.$nextTick(() => {
          this.$refs.flyout.style.marginBottom = `${this.$refs.openBtn.offsetHeight}px`;
          this.verticalPositionFlyout();
        })
      }
    }
  },
  mounted() {
    document.addEventListener('scroll', this.verticalPositionFlyout);
  },
  unmounted() {
    document.removeEventListener('scroll', this.verticalPositionFlyout);
  },
  methods: {
    closeMenu() {
      this.showMenu = false;
    },
    handleClick(event, item) {
      if (!item.url) {
        event.preventDefault();
      }

      if (item.emit) {
        this.$emit(item.emit, item.params)
      }

      this.closeMenu();
    },
    verticalPositionFlyout() {
      if (!this.showMenu) return;

      const btn = this.$refs.openBtn;
      const screenHeight = window.innerHeight;
      const btnBottom = btn.getBoundingClientRect().bottom;

      if (screenHeight / 2 < btnBottom) {
        this.openUp = true;
      } else {
        this.openUp = false;
      }
    }

  }
}
</script>
