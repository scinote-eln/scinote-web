<template>
  <div class="absolute">
    <img :src="this.url"
      class="absolute bg-sn-light-grey text-sn-black w-[300px] h-[260px] rounded pointer-events-none flex shadow-lg shrink-0" />
  </div>
</template>

<script>
export default {
  name: 'TooltipPreview',
  props: {
    tooltipId: String,
    url: String,
    preview_url: String,
    file_name: String,
    icon_html: String || null,
  },
}
</script>
