<template>
  <div class="bg-white rounded p-4 mb-4" v-if="total">
    <div class="flex items-center">
      <h2 class="flex items-center gap-2 mt-0 mb-4">
        <i class="sn-icon sn-icon-label-templates"></i>
        {{ i18n.t('search.index.label_templates') }}
        [{{ total }}]
      </h2>
      <SortFlyout v-if="selected" :sort="sort" @changeSort="changeSort"></SortFlyout>
    </div>
    <div>
      <div class="grid grid-cols-[auto_110px_auto_auto_auto_auto] items-center">
        <template v-for="row in preparedResults" :key="row.id">
          <a :href="row.attributes.url" class="h-full py-2 px-4 overflow-hidden font-bold border-0 border-b border-solid border-sn-light-grey">
            <StringWithEllipsis class="w-full" :text="row.attributes.name"></StringWithEllipsis>
          </a>
          <div class="h-full py-2 px-4 flex items-center gap-1 text-xs border-0 border-b border-solid border-sn-light-grey">
            <b class="shrink-0">{{ i18n.t('search.index.format') }}:</b>
            <span class="shrink-0">{{ row.attributes.format }}</span>
          </div>
          <div class="h-full py-2 px-4 flex items-center gap-1 text-xs border-0 border-b border-solid border-sn-light-grey">
            <b class="shrink-0">{{ i18n.t('search.index.created_at') }}:</b>
            <span class="shrink-0">{{ row.attributes.created_at }}</span>
          </div>
          <div class="h-full py-2 px-4 flex items-center gap-1 text-xs border-0 border-b border-solid border-sn-light-grey">
            <b class="shrink-0">{{ i18n.t('search.index.updated_at') }}:</b>
            <span class="shrink-0">{{ row.attributes.updated_at }}</span>
          </div>
          <div class="h-full py-2 px-4 flex items-center gap-1 text-xs border-0 border-b border-solid border-sn-light-grey">
            <b class="shrink-0">{{ i18n.t('search.index.created_by') }}:</b>
            <img v-if="row.attributes.created_by.avatar_url" :src="row.attributes.created_by.avatar_url" class="w-5 h-5 border border-sn-super-light-grey rounded-full mx-1" />
            <span class="shrink-0">{{ row.attributes.created_by.name }}</span>
          </div>
          <div class="h-full py-2 px-4 grid grid-cols-[auto_1fr] items-center gap-1 text-xs border-0 border-b border-solid border-sn-light-grey">
            <b class="shrink-0">{{ i18n.t('search.index.team') }}:</b>
            <a :href="row.attributes.team.url" class="shrink-0 overflow-hidden">
              <StringWithEllipsis class="w-full" :text="row.attributes.team.name"></StringWithEllipsis>
            </a>
          </div>
        </template>
      </div>
      <div v-if="!selected && total > 4" class="mt-4">
        <button class="btn btn-light" @click="$emit('selectGroup', 'LabelTemplatesComponent')">View all</button>
      </div>
    </div>
  </div>
</template>

<script>
import searchMixin from './search_mixin';

export default {
  name: 'LabelTemplatesComponent',
  mixins: [searchMixin],
  data() {
    return {
      group: 'label_templates'
    };
  }
};
</script>
