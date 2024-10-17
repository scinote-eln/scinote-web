<template>
  <div ref="container" class="w-full flex items-center flex-wrap gap-0.5">
    <template v-if="!allVisible">
      <div class="flex items-center gap-0.5">
        <a :href="breadcrumbs[0].url" :title="breadcrumbs[0].name" class="max-w-[200px]">
          <StringWithEllipsis class="w-full" :text="breadcrumbs[0].name"></StringWithEllipsis>
        </a>
      </div>
      <div class="flex items-center gap-0.5">
        <i class="sn-icon sn-icon-right text-sn-grey"></i>
        <GeneralDropdown>
          <template v-slot:field>
            <a>...</a>
          </template>
          <template v-slot:flyout>
            <div class="max-w-[600px]">
              <div v-for="(breadcrumb, index) in hiddenBreadcrumbs" :key="index" class="p-2 hover:bg-sn-super-light-grey cursor-pointer">
                <a :href="breadcrumb.url" :title="breadcrumb.name" class="max-w-[200px] hover:no-underline">
                  <StringWithEllipsis class="w-full" :text="breadcrumb.name"></StringWithEllipsis>
                </a>
              </div>
            </div>
          </template>
        </GeneralDropdown>
        <i class="sn-icon sn-icon-right text-sn-grey"></i>
      </div>
    </template>
    <div v-for="(breadcrumb, index) in visibleBreadcrumbs" :key="index" class="flex items-center gap-0.5">
      <i v-if="index > 0" class="sn-icon sn-icon-right text-sn-grey"></i>
      <a :href="breadcrumb.url" :title="breadcrumb.name" class="max-w-[200px]">
        <StringWithEllipsis class="w-full" :text="breadcrumb.name"></StringWithEllipsis>
      </a>
    </div>
  </div>
</template>

<script>
import StringWithEllipsis from './string_with_ellipsis.vue';
import GeneralDropdown from './general_dropdown.vue';

export default {
  name: 'Breadcrumbs',
  props: {
    breadcrumbs: {
      type: Array,
      required: true
    }
  },
  components: {
    StringWithEllipsis,
    GeneralDropdown
  },
  data() {
    return {
      containerSize: 0,
      breadcrumbSize: 200
    };
  },
  computed: {
    breadcrumbsVisibleCount() {
      const size = Math.floor(this.containerSize / this.breadcrumbSize);
      if (size < 2) {
        return 2;
      }
      return size;
    },
    allVisible() {
      return this.breadcrumbs.length <= this.breadcrumbsVisibleCount;
    },
    hiddenBreadcrumbs() {
      return this.breadcrumbs.slice(1, this.breadcrumbs.length - this.breadcrumbsVisibleCount + 1);
    },
    visibleBreadcrumbs() {
      if (this.allVisible) {
        return this.breadcrumbs;
      }
      return this.breadcrumbs.slice(this.breadcrumbs.length - this.breadcrumbsVisibleCount + 1);
    }
  },
  mounted() {
    this.setContainerSize();
    window.addEventListener('resize', this.setContainerSize);
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.setContainerSize);
  },
  methods: {
    setContainerSize() {
      this.containerSize = this.$refs.container.offsetWidth;
    }
  }
};
</script>;
