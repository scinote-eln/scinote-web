<template>
    <div class="h-full py-2 px-4 grid grid-cols-[auto_1fr] min-w-[8rem] items-center gap-1 text-xs group-hover:bg-sn-super-light-grey">
      <template v-if="visible">
        <b class="shrink-0">{{ label }}:</b>
        <a v-if="url" :href="url" class="shrink-0 overflow-hidden hover:no-underline">
          <img v-if="avatar" :src="avatar" class="w-5 h-5 border border-sn-super-light-grey rounded-full mx-1" />
          <StringWithEllipsis class="w-full" :text="value"></StringWithEllipsis>
        </a>
        <div v-else class="grid grid-cols-[auto_1fr] items-center gap-1 overflow-hidden">
          <img v-if="avatar" :src="avatar" class="w-5 h-5 border border-sn-super-light-grey rounded-full mx-1" />
          <span class="shrink-0 truncate" :title="value">{{ value }}</span>
        </div>
      </template>
    </div>
</template>

<script>
import StringWithEllipsis from '../../../shared/string_with_ellipsis.vue';

export default {
  name: 'CellTemplate',
  props: {
    label: { type: String, default: '' },
    value: { type: String, default: '' },
    url: { type: String, default: '' },
    avatar: { type: String, default: '' },
    visible: { type: Boolean, default: true }
  },
  components: {
    StringWithEllipsis
  }
};
</script>
