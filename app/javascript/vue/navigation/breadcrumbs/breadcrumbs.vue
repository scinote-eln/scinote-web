<template>
  <div class="breadcrumbs-container" ref="container">
    <a
      v-if="firstItem && firstItem.url !== lastItem.url"
      :href="firstItem.url"
      class="breadcrumbs-item"
      :title="firstItem.label"
      ref="firstItem"
    >
      <span
        class="breadcrumbs-link"
        :class="{
          shortened:
            state === State.SHORTENED || state === State.SHORTENED_COLLAPSED,
          'plain-text': !firstItem.url
        }"
        >{{ firstItem.label }}</span>
      <span class="delimiter">
        <img :src="delimiterUrl" alt="navigate next" class="navigate_next" />
      </span>
    </a>
    <template v-if="middleItems.length">
      <BreadcrumbsDropdown
        v-if="hiddenMiddleItems.length"
        :items="hiddenMiddleItems"
        :delimiterUrl="delimiterUrl"
      />
      <a
        v-for="(item, index) in visibleMiddleItems"
        :key="item.url"
        :href="item.url"
        class="breadcrumbs-item"
        :title="item.label"
        :ref="`visibleMiddleItem-${index}`"
      >
        <span
          class="breadcrumbs-link"
          :class="{
            shortened:
              state === State.SHORTENED || state === State.SHORTENED_COLLAPSED
          }"
          >{{ item.label }}</span
        >
        <span class="delimiter">
          <img :src="delimiterUrl" alt="navigate next" class="navigate_next" />
        </span>
      </a>
    </template>
    <span class="breadcrumbs-item" title="lastItem.label" ref="lastItem">
      <span
        class="breadcrumbs-link"
        :title="lastItem.label"
        :class="{
          shortened:
            state === State.SHORTENED || state === State.SHORTENED_COLLAPSED
        }"
        >{{ lastItem.label }}</span
      >
    </span>
  </div>
</template>

<script>
import BreadcrumbsDropdown from './breadcrumbs_dropdown.vue';

const State = Object.freeze({
  INITIAL: 'initial',
  EXPENDED: 'expended',
  SHORTENED: 'shortened',
  SHORTENED_COLLAPSED: 'shortened_collapsed'
});
const dropdownWidth = 60;
export default {
  name: 'Breadcrumbs',
  props: {
    breadcrumbsItems: String,
    delimiterUrl: String
  },
  data() {
    return {
      dropdownWidth,
      State,
      state: State.INITIAL,
      items: [],
      hiddenMiddleItems: [],
      visibleMiddleItems: []
    };
  },
  components: {
    BreadcrumbsDropdown
  },
  watch: {
    breadcrumbsItems: {
      immediate: true,
      handler() {
        this.items = JSON.parse(this.breadcrumbsItems);
        this.reset();
        this.$nextTick(() => {
          this.updateItems();
        });
      }
    }
  },
  computed: {
    firstItem() {
      if (this.items.length <= 1) {
        return null;
      }
      return this.items[0];
    },
    lastItem() {
      return this.items[this.items.length - 1];
    },
    middleItems() {
      if (this.items.length <= 2) return [];

      return this.items.slice(1, -1);
    }
  },
  methods: {
    updateItems() {
      const width = this.$refs.container.clientWidth;
      const scrollWidth = Array.from(this.$refs.container.children).reduce(
        (totalWidth, child) => totalWidth + child.offsetWidth,
        0
      );
      if (this.state === this.State.INITIAL) {
        if (width < scrollWidth) {
          this.state = this.State.SHORTENED;
          this.$nextTick(() => {
            this.updateItems();
          });
        } else {
          this.state = this.State.EXPENDED;
        }
      } else if (this.state === this.State.SHORTENED) {
        if (width < scrollWidth) {
          this.state = this.State.SHORTENED_COLLAPSED;
          let visibleWidth = this.dropdownWidth
            + this.$refs.firstItem.offsetWidth
            + this.$refs.lastItem.offsetWidth;
          let index = this.middleItems.length - 1;

          while (visibleWidth <= width && index >= 0) {
            visibleWidth += this.$refs[`visibleMiddleItem-${index}`][0]
              .offsetWidth;
            index--;
          }
          this.visibleMiddleItems = this.middleItems.slice(index + 2);
          this.hiddenMiddleItems = this.middleItems.slice(0, index + 2);
        }
      }
    },
    reset() {
      this.state = this.State.INITIAL;
      this.hiddenMiddleItems = [];
      this.visibleMiddleItems = this.middleItems;
    }
  }
};
</script>
