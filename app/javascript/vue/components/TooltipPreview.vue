<template>
  <div :id="tooltipId"
    class="absolute bg-sn-light-grey text-sn-black p-2 rounded pointer-events-none w-[300px] h-[260px] flex shadow-lg shrink-0 right-[8rem] bottom-[-26rem]">
    <div class="h-fit m-auto">FILE_PREVIEW_IMG_PLACEHOLDER (loaded from props in the future)</div>
  </div>
</template>

<script>
export default {
  name: 'TooltipPreview',
  props: {
    tooltipId: String
  },
}
</script>