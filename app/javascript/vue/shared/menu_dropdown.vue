<template>
  <div class="relative" v-if="listItems.length > 0 || alwaysShow" v-click-outside="closeMenu" >
    <button ref="field" :class="btnClasses" :title="title" @click="isOpen = !isOpen" :data-e2e="dataE2e">
      <i v-if="btnIcon" :class="btnIcon"></i>
      <span :class="{'tw-hidden lg:inline': smallScreenCollapse}">{{ btnText }}</span>
      <i v-if="caret && isOpen" class="sn-icon sn-icon-up"></i>
      <i v-else-if="caret" class="sn-icon sn-icon-down"></i>
    </button>
    <template v-if="isOpen">
      <teleport to="body">
        <div ref="flyout"
            class="fixed z-[3000] sn-menu-dropdown bg-sn-white rounded p-2.5 sn-shadow-menu-sm flex flex-col gap-[1px]"
            :class="{
                'right-0': position === 'right',
                'left-0': position === 'left',
            }"
        >
          <span v-for="(item, i) in listItems" :key="i" class="contents">
            <div v-if="item.dividerBefore" class="border-0 border-t border-solid border-sn-light-grey"></div>
            <a :href="item.url" v-if="!item.submenu"
              v-html="item.text"
              :target="item.url_target || '_self'"
              :class="{ 'bg-sn-super-light-blue': item.active, 'disabled': item.disabled }"
              :style="item.disabled === 'style-only' && 'pointer-events: all'"
              :title="item.title"
              :data-toggle="item.modalTarget && 'modal'"
              :data-target="item.modalTarget"
              :data-e2e="item.data_e2e"
              class="block whitespace-nowrap rounded px-3 py-2.5 hover:!text-sn-blue hover:no-underline cursor-pointer hover:bg-sn-super-light-grey leading-5 relative"
              @click="handleClick($event, item)"
            >
            </a>
            <div v-else class="-mx-2.5 px-2.5 group relative">
              <span
                :class="{ 'bg-sn-super-light-blue': item.active }"
                class="flex group items-center rounded relative text-sn-blue whitespace-nowrap px-3 py-2.5 hover:no-underline cursor-pointer
                      group-hover:bg-sn-super-light-blue hover:!bg-sn-super-light-grey"
                :data-e2e="item.data_e2e"
              >
                {{ item.text }}
                <i class="sn-icon sn-icon-right ml-auto"></i>
              </span>
              <div
                  class="absolute bg-sn-white rounded p-2.5 sn-shadow-menu-sm  flex flex-col gap-[1px] tw-hidden group-hover:block"
                  :class="{
                    'left-0 ml-[100%]': item.position === 'right',
                    'right-0 mr-[100%]': item.position === 'left',
                    'top-0': this.openDirection === 'down',
                    'bottom-0': this.openDirection === 'top'
                  }"
              >
                <a v-for="(sub_item, si) in item.submenu" :key="si"
                  :href="sub_item.url"
                  :traget="sub_item.url_target || '_self'"
                  :class="{ 'bg-sn-super-light-blue': item.active }"
                  :data-e2e="`${sub_item.data_e2e}`"
                  class="block whitespace-nowrap rounded px-3 py-2.5 hover:!text-sn-blue hover:no-underline cursor-pointer hover:bg-sn-super-light-grey leading-5"
                  @click="handleClick($event, sub_item)"
                >
                  {{ sub_item.text }}
                </a>
              </div>
            </div>
          </span>
        </div>
      </teleport>
    </template>
  </div>
</template>

<script>

import { vOnClickOutside } from '@vueuse/components';
import FixedFlyoutMixin from './mixins/fixed_flyout.js';

export default {
  name: 'DropdownMenu',
  props: {
    listItems: { type: Array, default: () => [] },
    position: { type: String, default: 'left' },
    btnClasses: { type: String, default: 'btn btn-light' },
    btnText: { type: String, required: false },
    btnIcon: { type: String, required: false },
    caret: { type: Boolean, default: false },
    alwaysShow: { type: Boolean, default: false },
    title: { type: String, default: '' },
    dataE2e: { type: String, default: '' },
    smallScreenCollapse: { type: Boolean, default: false }
  },
  data() {
    return {
      isOpen: false
    };
  },
  directives: {
    'click-outside': vOnClickOutside
  },
  mixins: [FixedFlyoutMixin],
  watch: {
    isOpen(newValue) {
      this.$emit('menu-toggle', newValue);
    }
  },
  methods: {
    closeMenu() {
      this.isOpen = false;
    },
    handleClick(event, item) {
      if (!item.url) {
        event.preventDefault();
      }

      if (item.emit) {
        this.$emit(item.emit, item.params);
        this.$emit('dtEvent', item.emit, item);
      }
      this.closeMenu();
    }
  }
};
</script>
