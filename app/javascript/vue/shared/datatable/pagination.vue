<template>
  <div v-if="pages.length > 1" class="flex gap-3 select-none">
    <div class="w-9 h-9">
      <div class="w-9 h-9 cursor-pointer flex items-center justify-center"
           @click="$emit('setPage', currentPage - 1)"
           v-if="currentPage > 1">
        <i class="sn-icon sn-icon-left cursor-pointer"></i>
      </div>
    </div>
    <div class="w-9 h-9 cursor-pointer flex items-center justify-center"
         v-for="page in pages"
         :class="{ 'border-solid rounded border-sn-science-blue': page === currentPage }"
         :key="page"
         @click="$emit('setPage', page)">
      <span >{{ page }}</span>
    </div>
    <div class="w-9 h-9">
      <div class="w-9 h-9 cursor-pointer flex items-center justify-center"
           @click="$emit('setPage', currentPage + 1)"
           v-if="totalPage > currentPage">
        <i class="sn-icon sn-icon-right cursor-pointer"></i>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'Pagination',
  props: {
    totalPage: {
      type: Number,
      required: true,
    },
    currentPage: {
      type: Number,
      required: true,
    },
  },
  computed: {
    pages() {
      const pages = [];
      for (let i = 1; i <= this.totalPage; i += 1) {
        if (i >= this.currentPage - 2 || this.totalPage <= 5) {
          pages.push(i);
        }

        if (pages.length === 5) {
          break;
        }
      }
      return pages;
    },
  },
};
</script>
