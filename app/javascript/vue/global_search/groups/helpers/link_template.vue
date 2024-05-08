<template>
    <a target="_blank" :href="url"
       class="h-full py-2 px-4 flex gap-1 items-center font-bold overflow-hidden group-hover:bg-sn-super-light-grey hover:no-underline"
    >
      <span v-if="icon" :class="icon" class="sn-icon shrink-0"></span>
      <StringWithEllipsis
        :class="{
          'w-full': !icon,
          'w-[calc(100%-2rem)]': icon
        }"
        :text="value">
      </StringWithEllipsis>
    </a>
</template>

<script>
import StringWithEllipsis from '../../../shared/string_with_ellipsis.vue';

export default {
  name: 'LinkTemplate',
  props: {
    value: { type: String, default: '' },
    url: { type: String, default: '' },
    icon: { type: String, default: '' }
  },
  components: {
    StringWithEllipsis
  }
};
</script>
