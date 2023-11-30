<template>
  <div v-if="!params.folder" class="p-4 rounded sn-shadow-flyout flex flex-col">
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
    <a :href="params.urls.show" class="font-bold mb-4 text-sn-black hover:no-underline hover:text-sn-black">
      {{ params.name }}
    </a>
    <div class="grid gap-2 grid-cols-[80px_auto] mt-auto">
      <span class="text-sn-grey">{{ i18n.t('projects.index.card.start_date') }}</span>
      <span class="font-bold">{{ params.created_at }}</span>

      <template v-if="params.archived_on">
        <span class="text-sn-grey">{{ i18n.t('projects.index.card.archived_date') }}</span>
        <span class="font-bold">{{ params.archived_on }}</span>
      </template>
      <span class="text-sn-grey">{{ i18n.t('projects.index.card.visibility') }}</span>
      <span class="font-bold">{{ params.hidden ? i18n.t('projects.index.hidden') : i18n.t('projects.index.visible') }}</span>

      <span class="text-sn-grey">{{ i18n.t('projects.index.card.users') }}</span>
      <UsersRenderer :params="{data: params, value: params.users}" class="-mt-2.5" />
    </div>
  </div>
  <div v-else class="p-4 rounded sn-shadow-flyout flex flex-col">
    <div class="flex items-center gap-2 mb-2">
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
    <div class="flex-grow flex items-center justify-center min-h-[6rem] text-sn-blue">
      <i class="sn-icon sn-icon-folder"></i>
    </div>
    <a :href="params.urls.show" class="flex items-center justify-center gap-1 font-bold mb-2 text-sn-black hover:no-underline hover:text-sn-black">
      <i class="sn-icon mini sn-icon-mini-folder-left"></i>
      {{ params.name }}
    </a>
    <div class="flex items-center justify-center">
      {{ params.folder_info }}
    </div>
  </div>
</template>

<script>

import RowMenuRenderer from '../shared/datatable/row_menu_renderer.vue'
import UsersRenderer from './renderers/users.vue'
import CardSelectorMixin from '../shared/datatable/mixins/card_selector.js'

export default {
  name: "ProjectCard",
  props: {
    params: Object,
    dtComponent: Object
  },
  components: {
    RowMenuRenderer,
    UsersRenderer
  },
  mixins: [CardSelectorMixin]
}
</script>