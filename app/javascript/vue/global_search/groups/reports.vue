<template>
  <div ref="content" class="bg-white rounded" :class="{ 'p-4 mb-4': results.length || loading }">
    <template v-if="total && results.length">
      <div class="flex items-center">
        <h2 class="flex items-center gap-2 mt-0 mb-4">
          <i class="sn-icon sn-icon-reports"></i>
          {{ i18n.t('search.index.reports') }}
          [{{ total }}]
        </h2>
        <SortFlyout v-if="selected" :sort="sort" @changeSort="changeSort"></SortFlyout>
      </div>
      <div class="grid grid-cols-[auto_110px_auto_auto_auto_auto_auto] items-center">
        <template v-for="row in preparedResults" :key="row.id">
          <a target="_blank" :href="row.attributes.url" class="h-full py-2 px-4 overflow-hidden font-bold border-0 border-b border-solid border-sn-light-grey">
            <StringWithEllipsis class="w-full" :text="row.attributes.name"></StringWithEllipsis>
          </a>
          <div class="h-full py-2 px-4 flex items-center gap-1 text-xs border-0 border-b border-solid border-sn-light-grey">
            <b class="shrink-0">{{ i18n.t('search.index.id') }}:</b>
            <span class="shrink-0">{{ row.attributes.code }}</span>
          </div>
          <div class="h-full py-2 px-4 flex items-center gap-1 text-xs border-0 border-b border-solid border-sn-light-grey">
            <b class="shrink-0">{{ i18n.t('search.index.created_at') }}:</b>
            <span class="shrink-0">{{ row.attributes.created_at }}</span>
          </div>
          <div class="h-full py-2 px-4 flex items-center gap-1 text-xs border-0 border-b border-solid border-sn-light-grey">
            <b class="shrink-0">{{ i18n.t('search.index.updated_at') }}:</b>
            <span class="shrink-0">{{ row.attributes.updated_at }}</span>
          </div>
          <div class="h-full py-2 px-4 grid grid-cols-[auto_1fr] items-center gap-1 text-xs border-0 border-b border-solid border-sn-light-grey">
            <b class="shrink-0">{{ i18n.t('search.index.created_by') }}:</b>
            <div class="truncate">
              <img :src="row.attributes.created_by.avatar_url" class="w-5 h-5 border border-sn-super-light-grey rounded-full mx-1" />
              <span class="truncate">{{ row.attributes.created_by.name }}</span>
            </div>
          </div>
          <div class="h-full py-2 px-4 grid grid-cols-[auto_1fr] items-center gap-1 text-xs border-0 border-b border-solid border-sn-light-grey">
            <b class="shrink-0">{{ i18n.t('search.index.team') }}:</b>
            <a target="_blank" :href="row.attributes.team.url" class="shrink-0 overflow-hidden">
              <StringWithEllipsis class="w-full" :text="row.attributes.team.name"></StringWithEllipsis>
            </a>
          </div>
          <div class="h-full py-2 px-4 grid grid-cols-[auto_1fr] items-center gap-1 text-xs border-0 border-b border-solid border-sn-light-grey">
            <b class="shrink-0">{{ i18n.t('search.index.project') }}:</b>
            <a target="_blank" :href="row.attributes.project.url" class="shrink-0 overflow-hidden">
              <StringWithEllipsis class="w-full" :text="row.attributes.project.name"></StringWithEllipsis>
            </a>
          </div>
        </template>
      </div>
      <div v-if="viewAll" class="mt-4">
        <button class="btn btn-light" @click="$emit('selectGroup', 'ReportsComponent')">View all</button>
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
  name: 'ReportsComponent',
  mixins: [searchMixin],
  data() {
    return {
      group: 'reports'
    };
  }
};
</script>
