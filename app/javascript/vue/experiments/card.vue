<template>
  <div class="p-4 rounded sn-shadow-flyout flex flex-col"
       :class="{'bg-sn-light-grey': dtComponent.currentViewMode === 'archived'}">
    <div class="flex items-center gap-2 mb-2">
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
       :class="{'pointer-events-none text-sn-grey': !params.urls.show}"
       class="font-bold mb-4 text-sn-black hover:no-underline hover:text-sn-black">
      {{ params.name }}
    </a>
    <div class="flex">
      <div class="grid gap-2 grid-cols-[100px_auto] mt-auto">
        <span class="text-sn-grey">{{ i18n.t('experiments.card.start_date') }}</span>
        <span class="font-bold">{{ params.created_at }}</span>

        <span class="text-sn-grey">{{ i18n.t('experiments.card.modified_date') }}</span>
        <span class="font-bold">{{ params.updated_at }}</span>

        <template v-if="dtComponent.viewMode == 'archived'">
          <span class="text-sn-grey">{{ i18n.t('experiments.card.archived_date') }}</span>
          <span class="font-bold">{{ params.archived_on }}</span>
        </template>

        <span class="text-sn-grey">{{ i18n.t('experiments.card.completed_task') }}</span>
        <span class="font-bold">{{ i18n.t(
          'experiments.card.completed_value', {
            completed: params.completed_tasks,
            all: params.total_tasks
          }
        ) }}</span>
      </div>
      <div class="h-20 w-20 p-0.5 bg-sn-light-grey rounded-sm shrink-0 ml-auto relative">
        <div v-if="imageLoading" class="flex absolute top-0 items-center justify-center w-full flex-grow h-full z-10">
          <img src="/images/medium/loading.svg" alt="Loading" />
        </div>
        <img v-else :src="workflow_img" class="max-h-18 max-w-[72px]">
      </div>
    </div>
    <div class="py-2">
      <div class="w-full h-1 bg-sn-light-grey">
        <div class="h-full bg-sn-blue" :style="{
          width: params.completed_tasks / params.total_tasks * 100 + '%'
        }"></div>
      </div>
    </div>
    <Description :params="{data: params, value: params.description, dtComponent: dtComponent}" />
  </div>
</template>

<script>

import RowMenuRenderer from '../shared/datatable/row_menu_renderer.vue';
import CardSelectorMixin from '../shared/datatable/mixins/card_selector.js';
import workflowImgMixin from './workflow_img_mixin.js';
import Description from './renderers/description.vue';

export default {
  name: 'ProjectCard',
  props: {
    params: Object,
    dtComponent: Object,
  },
  components: {
    RowMenuRenderer,
    Description,
  },
  mixins: [CardSelectorMixin, workflowImgMixin],
};
</script>
