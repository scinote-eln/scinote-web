<template>
  <div ref="noSearchResult" class="h-[60vh]">
    <div class="flex flex-col gap-6 bg-sn-white text-center relative top-1/4">
       <div><span class=" inline-block sn-icon sn-icon-search"></span></div>
       <div class="">
         <p class="text-sn-black text-2xl font-semibold">
           {{ i18n.t('search.index.no_results_text') }}
         </p>
         <p class="text-sn-dark-grey text-base">
           {{ i18n.t('search.index.adjust_search_text') }}
         </p>
       </div>
     </div>
  </div>
</template>

<script>

export default {
  name: 'NoSearchResult'
};
</script>
