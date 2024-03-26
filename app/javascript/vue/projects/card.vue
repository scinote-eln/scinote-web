<template>
  <div v-if="!params.folder"
       :class="{ 'bg-sn-light-grey': dtComponent.currentViewMode === 'archived', [cardMinWidth]: true }"
       class="px-3 pt-3 pb-4 rounded border-solid border border-sn-gray flex flex-col h-56" >
    <div class="flex items-center gap-4 mb-2">
      <div class="sci-checkbox-container">
        <input
          type="checkbox"
          class="sci-checkbox"
          @change="itemSelected"
        />
        <label :for="params.id" class="sci-checkbox-label"></label>
      </div>
      <div>{{ params.code }}</div>
      <RowMenuRenderer :params="{data: params, dtComponent: dtComponent}" class="ml-auto"/>
    </div>
    <a :href="params.urls.show"
       :title="params.name"
       :class="{'pointer-events-none text-sn-grey': !params.urls.show}"
       class="font-bold mb-4 text-sn-blue hover:no-underline line-clamp-3 hover:text-sn-blue h-[60px]">
      {{ params.name }}
    </a>
    <div class="grid gap-x-2 gap-y-3 grid-cols-[90px_auto] mt-auto text-xs">
      <span class="text-sn-dark-grey">{{ i18n.t('projects.index.card.start_date') }}</span>
      <span class="font-bold">{{ params.created_at }}</span>

      <template v-if="dtComponent.currentViewMode == 'archived'">
        <span class="text-sn-dark-grey">{{ i18n.t('projects.index.card.archived_date') }}</span>
        <span class="font-bold">{{ params.archived_on }}</span>
      </template>
      <template v-else>
        <span class="text-sn-dark-grey">{{ i18n.t('projects.index.card.updated_on') }}</span>
        <span class="font-bold">{{ params.updated_at }}</span>
      </template>
      <span class="text-sn-dark-grey">{{ i18n.t('projects.index.card.users') }}</span>
      <UsersRenderer :params="{data: params, value: params.users, dtComponent: dtComponent}" class="-mt-2.5" />
    </div>
  </div>
  <div v-else
    class="px-3 pt-3 pb-4 rounded border-solid border border-sn-gray flex flex-col h-56"
    :class="{
      'bg-sn-light-grey': dtComponent.currentViewMode === 'archived',
      'bg-sn-super-light-grey': dtComponent.currentViewMode !== 'archived',
      [cardMinWidth]: true
    }"
  >
    <div class="flex items-center gap-4 mb-2">
      <div class="sci-checkbox-container">
        <input
          type="checkbox"
          class="sci-checkbox"
          @change="itemSelected"
        />
        <label :for="params.id" class="sci-checkbox-label"></label>
      </div>
      <RowMenuRenderer :params="{data: params, dtComponent: dtComponent}" class="ml-auto"/>
    </div>
    <div
      class="flex flex-col items-center justify-center"
      :class="{
        'text-sn-black hover:text-sn-black': dtComponent.currentViewMode === 'archived',
        'text-sn-blue hover:text-sn-blue': dtComponent.currentViewMode !== 'archived'
      }"
     >
      <i class="sn-icon sn-icon-folder " style="font-size: 56px !important"></i>
      <a :href="params.urls.show"
        class="line-clamp-2 font-bold mb-2 text-inherit text-center hover:no-underline ">
        {{ params.name }}
      </a>
      <div class="flex items-center justify-center text-sn-dark-grey">
        {{ params.folder_info }}
      </div>
    </div>
  </div>
</template>

<script>

/* global GLOBAL_CONSTANTS */

import RowMenuRenderer from '../shared/datatable/row_menu_renderer.vue';
import UsersRenderer from './renderers/users.vue';
import CardSelectorMixin from '../shared/datatable/mixins/card_selector.js';

export default {
  name: 'ProjectCard',
  props: {
    params: Object,
    dtComponent: Object,
  },
  computed: {
    cardMinWidth() {
      return `min-w-[${GLOBAL_CONSTANTS.TABLE_CARD_MIN_WIDTH}px]`;
    }
  },
  components: {
    RowMenuRenderer,
    UsersRenderer,
  },
  mixins: [CardSelectorMixin],
};
</script>
