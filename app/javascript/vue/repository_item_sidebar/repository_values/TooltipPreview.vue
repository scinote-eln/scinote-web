<template>
  <div>
    <img :src="this.medium_preview_url" @load="onImageLoaded($event)"
      class="absolute bg-sn-light-grey text-sn-black rounded pointer-events-none flex shadow-lg"
      :class="{ hidden: !showImage, 'top-0 transform -translate-y-full': showTop }"/>
  </div>
</template>

<script>
export default {
  name: 'TooltipPreview',
  data() {
    return {
      showTop: false,
      showImage: false,
    }
  },
  props: {
    tooltipId: String,
    url: String,
    preview_url: String,
    file_name: String,
    icon_html: String || null,
    medium_preview_url: String || null,
  },
  methods: {
    onImageLoaded(event) {
      this.showTop = !this.isInViewPort(event.target);
      this.showImage = true;
    },

    isInViewPort(el) {
      if (!el) return;

      const height = el.naturalHeight;
      const rect = el.parentElement.getBoundingClientRect();

      return (
        (rect.bottom + height) <=
          (window.innerHeight || document.documentElement.clientHeight)
      );
}

  }
}
</script>
