<template>
  <div ref="content" class="bg-white rounded" :class="{ 'p-4 mb-4': results.length || loading }"  :data-e2e="'e2e-CO-globalSearch-folders'">
    <template v-if="total && results.length">
      <div class="flex items-center">
        <h2 class="flex items-center gap-2 mt-0 mb-4">
          <i class="sn-icon sn-icon-folder"></i>
          {{ i18n.t('search.index.folders') }}
          <span class="text-base" >[{{ total }}]</span>
        </h2>
        <SortFlyout v-if="selected" :sort="sort" @changeSort="changeSort" :e2eSortButton="'e2e-BT-globalSearch-folders-sort'"></SortFlyout>
      </div>
      <div class="grid grid-cols-[auto_110px_auto_auto_auto] items-center">
        <TableHeader :selected="selected" :columnNames="[
          i18n.t('search.index.id'),
          i18n.t('search.index.created_at'),
          i18n.t('search.index.folder'),
          i18n.t('search.index.team')
        ]"></TableHeader>
        <div v-for="(row, index) in preparedResults" :key="row.id" class="contents group">
          <hr class="col-span-5 w-full m-0" v-if="index > 0">
          <LinkTemplate :url="row.url"  :value="labelName({ name: row.name, archived: row.archived})"/>
          <CellTemplate :label="i18n.t('search.index.id')" :value="row.code"/>
          <CellTemplate :label="i18n.t('search.index.created_at')" :value="row.created_at"/>
          <CellTemplate :label="i18n.t('search.index.folder')" :visible="row.parent_folder"
                        :url="row.parent_folder?.url" :value="labelName(row.parent_folder)"/>
          <CellTemplate :label="i18n.t('search.index.team')" :url="row.team.url" :value="row.team.name"/>
        </div>
      </div>
      <div v-if="viewAll">
        <hr class="w-full mb-4 mt-0">
        <button class="btn btn-light" @click="$emit('selectGroup', 'FoldersComponent')" :data-e2e="'e2e-BT-globalSearch-folders-viewAll'">View all</button>
      </div>
    </template>
    <Loader v-if="loading" :loaderRows="loaderRows" />
    <ListEnd v-if="reachedEnd && preparedResults.length > 0" />
    <NoSearchResult v-else-if="showNoSearchResult"  />
  </div>
</template>

<script>
import searchMixin from './search_mixin';

export default {
  name: 'FoldersComponent',
  mixins: [searchMixin],
  data() {
    return {
      group: 'project_folders'
    };
  }
};
</script>
