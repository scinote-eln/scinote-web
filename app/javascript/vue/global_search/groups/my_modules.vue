<template>
  <div v-if="total" class="bg-white rounded p-4 mb-4">
    <h2 class="flex items-center gap-2 mt-0 mb-4">
      <i class="sn-icon sn-icon-task"></i>
      {{ i18n.t('search.index.tasks') }}
      [{{ total }}]
    </h2>
    <div>
      <div class="grid grid-cols-[auto_80px_auto_auto_auto_auto] items-center">
        <template v-for="row in preparedResults" :key="row.id">
          <a :href="row.attributes.url" target="_blank" class="h-full py-2 px-4 overflow-hidden font-bold border-0 border-b border-solid border-sn-light-grey">
            <StringWithEllipsis class="w-full" :text="row.attributes.name"></StringWithEllipsis>
          </a>
          <div class="h-full py-2 px-4 flex items-center gap-1 text-xs border-0 border-b border-solid border-sn-light-grey">
            <b class="shrink-0">{{ i18n.t('search.index.id') }}:</b>
            <span class="shrink-0">{{ row.attributes.code }}</span>
          </div>
          <div class="h-full py-2 px-4 flex items-center gap-1 text-xs border-0 border-b border-solid border-sn-light-grey max-w-[200px]">
            <b class="shrink-0">{{ i18n.t('search.index.created_at') }}:</b>
            <span class="truncate">{{ row.attributes.created_at }}</span>
          </div>
          <div class="h-full py-2 px-4 flex items-center gap-1 text-xs border-0 border-b border-solid border-sn-light-grey max-w-[200px]">
            <b class="shrink-0">{{ i18n.t('search.index.updated_at') }}:</b>
            <span class="truncate">{{ row.attributes.updated_at }}</span>
          </div>
          <div class="h-full py-2 px-4 grid grid-cols-[auto_1fr] items-center gap-1 text-xs border-0 border-b border-solid border-sn-light-grey">
            <b class="shrink-0">{{ i18n.t('search.index.team') }}:</b>
            <a :href="row.attributes.team.url" class="shrink-0 overflow-hidden" target="_blank">
              <StringWithEllipsis class="w-full" :text="row.attributes.team.name"></StringWithEllipsis>
            </a>
          </div>
          <div class="h-full py-2 px-4 border-0 border-b border-solid border-sn-light-grey">
            <div class="grid grid-cols-[auto_1fr] items-center gap-1 text-xs w-full">
              <b class="shrink-0">{{ i18n.t('search.index.experiment') }}:</b>
              <a :href="row.attributes.experiment.url" class="shrink-0 overflow-hidden" target="_blank">
                <StringWithEllipsis class="w-full" :text="row.attributes.experiment.name"></StringWithEllipsis>
              </a>
            </div>
          </div>
        </template>
      </div>
      <div v-if="viewAll" class="mt-4">
        <button class="btn btn-light" @click="$emit('selectGroup', 'MyModulesComponent')">View all</button>
      </div>
    </div>
  </div>
</template>

<script>
import searchMixin from './search_mixin';

export default {
  name: 'MyModulesComponent',
  mixins: [searchMixin],
  data() {
    return {
      group: 'tasks'
    };
  }
};
</script>
