<template>
  <div>
    <div class="text-sn-blue cursor-pointer" @click="openItemCard">
      {{ this.params.value  }}
    </div>
  </div>
</template>

<script>
import {
  repository_repository_row_path
 } from '../../../routes.js';

export default {
  name: 'ConnectionsRender',
  props: {
    params: {
      required: true
    }
  },
  computed: {
    recordInfoUrl() {
      return repository_repository_row_path(
        this.params.data.repository_id,
        this.params.data.id
      );
    }
  },
  methods: {
    openItemCard() {
      window.repositoryItemSidebarComponent.toggleShowHideSidebar(this.recordInfoUrl, null, 'relationships-section');
    }
  }
};
</script>
