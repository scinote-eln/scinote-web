<template>
  <div ref="content" class="bg-white rounded" :class="{ 'p-4 mb-4': results.length || loading }" :data-e2e="'e2e-CO-globalSearch-files'">
    <template v-if="total && results.length">
      <div class="flex items-center">
        <h2 class="flex items-center gap-2 mt-0 mb-4">
          <i class="sn-icon sn-icon-files"></i>
          {{ i18n.t('search.index.files') }}
          <span class="text-base" >[{{ total }}]</span>
        </h2>
        <SortFlyout v-if="selected" :sort="sort" @changeSort="changeSort" :e2eSortButton="'e2e-BT-globalSearch-files-sort'"></SortFlyout>
      </div>
      <div class="grid grid-cols-[auto_auto_auto_auto_auto_auto] items-center">
        <TableHeader :selected="selected" :columnNames="[
          i18n.t('search.index.created_at'),
          i18n.t('search.index.updated_at'),
          '',
          '',
          i18n.t('search.index.team')
        ]"></TableHeader>
        <div v-for="(row, index) in preparedResults" :key="row.id" class="contents group">
          <hr class="col-span-6 w-full m-0" v-if="index > 0">
          <LinkTemplate :url="row.attributes.parent.url" :icon="row.attributes.icon" :value="row.attributes.file_name"/>
          <CellTemplate :label="i18n.t('search.index.created_at')" :value="row.attributes.created_at"/>
          <CellTemplate :label=" i18n.t('search.index.updated_at')" :value="row.attributes.updated_at"/>
          <CellTemplate :label="i18n.t(`search.index.${row.attributes.parent.type}`)" :url="row.attributes.parent.url" :value="labelName(row.attributes.parent)"/>
          <CellTemplate v-if="row.attributes.repository.name" :label="i18n.t(`search.index.repository`)"
                        :url="row.attributes.repository.url" :value="labelName(row.attributes.repository)"/>
          <CellTemplate v-else-if="row.attributes.experiment.name" :label="i18n.t(`search.index.experiment`)"
                        :url="row.attributes.experiment.url" :value="labelName(row.attributes.experiment)"/>
          <div v-else></div>
          <CellTemplate :label="i18n.t('search.index.team')" :url="row.attributes.team.url" :value="row.attributes.team.name"/>
        </div>
      </div>
      <div v-if="viewAll">
        <hr class="w-full mb-4 mt-0">
        <button class="btn btn-light" @click="$emit('selectGroup', 'AssetsComponent')" :data-e2e="'e2e-BT-globalSearch-files-viewAll'">View all</button>
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
  name: 'AssetsComponent',
  mixins: [searchMixin],
  data() {
    return {
      group: 'assets'
    };
  }
};
</script>
