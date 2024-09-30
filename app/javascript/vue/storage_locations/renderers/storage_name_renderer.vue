<template>
  <div class="flex gap-4">
    <a @mouseenter="openPreview" @mouseleave="hidePreview" class="hover:no-underline cursor-pointer flex items-center gap-1"
       :title="params.data.name"
       :href="params.data.urls.show">
      <i v-if="params.data.shared || params.data.ishared" class="fas fa-users"></i>
      <i v-if="params.data.container" class="sn-icon sn-icon-item"></i>
      <span class="truncate">{{ params.data.name }}</span>
    </a>
    <GeneralDropdown v-if="params.data.img_url" ref="imagePreview" >
      <template v-slot:flyout>
        <img class="w-48 h-48 object-cover" :src="params.data.img_url" @mouseenter="openPreview" @mouseleave="hidePreview">
      </template>
    </GeneralDropdown>
  </div>
</template>

<script>
import GeneralDropdown from '../../shared/general_dropdown.vue';

export default {
  name: 'StorageNameRenderer',
  components: {
    GeneralDropdown
  },
  props: {
    params: {
      type: Object,
      required: true
    }
  },
  methods: {
    openPreview() {
      if (this.$refs.imagePreview) {
        this.$refs.imagePreview.isOpen = true;
      }
    },
    hidePreview() {
      if (this.$refs.imagePreview) {
        this.$refs.imagePreview.isOpen = false;
      }
    }
  }
};
</script>
