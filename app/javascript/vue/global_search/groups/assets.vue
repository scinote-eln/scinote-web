<template>
  <div ref="content" class="bg-white rounded" :class="{ 'p-4 mb-4': results.length || loading }">
    <template v-if="total && results.length">
      <div class="flex items-center">
        <h2 class="flex items-center gap-2 mt-0 mb-4">
          <i class="sn-icon sn-icon-files"></i>
          {{ i18n.t('search.index.files') }}
          [{{ total }}]
        </h2>
        <SortFlyout v-if="selected" :sort="sort" @changeSort="changeSort"></SortFlyout>
      </div>
      <div class="grid grid-cols-[auto_auto_auto_auto_auto_auto] items-center">
        <template v-for="row in preparedResults" :key="row.id">
          <a target="_blank" :href="row.attributes.parent.url"
             class="h-full py-2 px-4 grid grid-cols-[auto_1fr] items-center gap-1 font-bold border-0 border-b border-solid border-sn-light-grey">
            <span :class="row.attributes.icon" class="shrink-0"></span>
            <StringWithEllipsis class="w-full" :text="row.attributes.file_name"></StringWithEllipsis>
          </a>
          <div class="h-full py-2 px-4 flex items-center gap-1 text-xs border-0 border-b border-solid border-sn-light-grey">
            <b class="shrink-0">{{ i18n.t('search.index.created_at') }}:</b>
            <span class="truncate">{{ row.attributes.created_at }}</span>
          </div>
          <div class="h-full py-2 px-4 flex items-center gap-1 text-xs border-0 border-b border-solid border-sn-light-grey">
            <b class="shrink-0">{{ i18n.t('search.index.updated_at') }}:</b>
            <span class="truncate">{{ row.attributes.updated_at }}</span>
          </div>
          <div class="h-full py-2 px-4 grid grid-cols-[auto_1fr] items-center gap-1 text-xs border-0 border-b border-solid border-sn-light-grey">
            <b class="shrink-0">{{ i18n.t('search.index.team') }}:</b>
            <a target="_blank" :href="row.attributes.team.url" class="shrink-0 overflow-hidden">
              <StringWithEllipsis class="w-full" :text="row.attributes.team.name"></StringWithEllipsis>
            </a>
          </div>
          <div class="h-full py-2 px-4 grid grid-cols-[auto_1fr] items-center gap-1 text-xs border-0 border-b border-solid border-sn-light-grey">
            <b class="shrink-0">{{ i18n.t(`search.index.${row.attributes.parent.type}`) }}:</b>
            <a target="_blank" :href="row.attributes.parent.url" class="shrink-0 overflow-hidden">
              <StringWithEllipsis class="w-full" :text="labelName(row.attributes.parent)"></StringWithEllipsis>
            </a>
          </div>
          <div class="s h-full py-2 px-4 grid grid-cols-[auto_1fr] items-center gap-1 text-xs border-0 border-b border-solid border-sn-light-grey"
               :class="{ 'invisible': !row.attributes.experiment.name }">
            <b class="shrink-0">{{ i18n.t('search.index.experiment') }}:</b>
            <a target="_blank" :href="row.attributes.experiment.url" class="shrink-0 overflow-hidden">
              <StringWithEllipsis class="w-full" :text="labelName(row.attributes.experiment)"></StringWithEllipsis>
            </a>
          </div>
        </template>
      </div>
      <div v-if="viewAll" class="mt-4">
        <button class="btn btn-light" @click="$emit('selectGroup', 'AssetsComponent')">View all</button>
      </div>
    </template>
    <Loader v-if="loading" :total="total" :loaderRows="loaderRows" :loaderYPadding="loaderYPadding"
            :loaderHeight="loaderHeight" :loaderGap="loaderGap" :reachedEnd="reachedEnd" />
   <NoSearchResult v-else-if="showNoSearchResult" :noSearchResultHeight="noSearchResultHeight"  />
  </div>
</template>

<script>
import searchMixin from './search_mixin';

export default {
  name: 'AssetsComponent',
  mixins: [searchMixin],
  data() {
    return {
      group: 'assets'
    };
  }
};
</script>
