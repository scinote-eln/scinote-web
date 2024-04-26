<template>
  <div ref="content" class="bg-white rounded" :class="{ 'p-4 mb-4': results.length || loading }">
    <template v-if="total && results.length">
      <div class="flex items-center">
        <h2 class="flex items-center gap-2 mt-0 mb-4">
          <i class="sn-icon sn-icon-inventory"></i>
          {{ i18n.t('search.index.inventory_items') }}
          <span class="text-base" >[{{ total }}]</span>
        </h2>
        <SortFlyout v-if="selected" :sort="sort" @changeSort="changeSort"></SortFlyout>
      </div>
      <div class="grid grid-cols-[auto_110px_auto_auto_auto_auto] items-center">
        <div v-for="(row, index) in preparedResults" :key="row.id" class="contents group">
          <hr class="col-span-6 w-full m-0" v-if="index > 0">
          <LinkTemplate :url="row.attributes.url" :value="labelName({ name: row.attributes.name, archived: row.attributes.archived})"/>
          <CellTemplate :label="i18n.t('search.index.id')" :value="row.attributes.code"/>
          <CellTemplate :label="i18n.t('search.index.created_at')" :value="row.attributes.created_at"/>
          <CellTemplate :label="i18n.t('search.index.created_by')" :avatar="row.attributes.created_by.avatar_url" :value="row.attributes.created_by.name"/>
          <CellTemplate :label="i18n.t('search.index.team')" :url="row.attributes.team.url" :value="row.attributes.team.name"/>
          <CellTemplate :label="i18n.t('search.index.repository')" :url="row.attributes.repository.url" :value="labelName(row.attributes.repository)"/>
        </div>
      </div>
      <div v-if="viewAll">
        <hr class="w-full mb-4 mt-0">
        <button class="btn btn-light" @click="$emit('selectGroup', 'RepositoryRowsComponent')">View all</button>
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
  name: 'RepositoryRowsComponent',
  mixins: [searchMixin],
  data() {
    return {
      group: 'repository_rows'
    };
  }
};
</script>
