<template>
  <div v-if="params.value">
    <a  :href="params.value.value.url"
        class="file-preview-link file-name"
        :id="`modal_link${params.value.value.id}`"
        data-no-turbolink="true"
        :data-id="params.value.value.id"
        :data-preview-url="previewUrl"
    >
      {{ params.value.value.file_name }}
    </a>
  </div>
</template>

<script>

import {
  asset_file_preview_path
} from '../../../../routes.js';

export default {
  name: 'AssetValue',
  props: {
    params: {
      required: true
    }
  },
  computed: {
    previewUrl() {
      return asset_file_preview_path(this.params.value.value.id, { preview: true });
    }
  }
};
</script>
