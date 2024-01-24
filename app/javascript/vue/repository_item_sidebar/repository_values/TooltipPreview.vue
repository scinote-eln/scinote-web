<template>
  <div>
    <img :src="this?.medium_preview_url" @load="onImageLoaded($event)" @error="onErrorImageLoaded($event)"
      class="absolute bg-sn-light-grey text-sn-black rounded pointer-events-none flex shadow-lg z-10"
      :class="{ hidden: !showImage, 'top-0 transform -translate-y-full': showTop }" />
    <div v-if="imageLoading" ref="imageLoader"
         class="absolute w-[218px] flex items-center justify-center bg-sn-white
                rounded border border-solid border-sn-light-grey z-10"
        :class="{'top-0 transform -translate-y-full': showTop, [`h-[${defaultLoaderHeight}px]`]: true }">
      <div class="sci-loader"></div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'TooltipPreview',
  data() {
    return {
      showTop: false,
      showImage: false,
      imageLoading: false
    };
  },
  props: {
    tooltipId: String,
    url: String,
    preview_url: String,
    file_name: String,
    icon_html: String || null,
    medium_preview_url: String || null,
    defaultLoaderHeight: {
      type: Number,
      default: 254
    }
  },
  methods: {
    onImageLoaded(event) {
      this.showTop = !this.isInViewPort(event.target);
      this.imageLoading = false;
      this.showImage = true;
      ActiveStoragePreviews.showPreview(event);
    },
    onErrorImageLoaded(event) {
      this.showTop = !this.isInViewPort(event.target);
      this.imageLoading = true;
      ActiveStoragePreviews.reCheckPreview(event);
    },
    isInViewPort(el) {
      if (!el) return;

      const height = el.naturalHeight || this.defaultLoaderHeight;
      const rect = el.parentElement.getBoundingClientRect();

      return (
        (rect.bottom + height)
        <= (window.innerHeight || document.documentElement.clientHeight)
      );
    }

  }
};
</script>
