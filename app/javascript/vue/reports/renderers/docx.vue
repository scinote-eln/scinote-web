<template>
  <div class="group w-full h-full">
    <template v-if="docx.error">
      <span class="flex items-center gap-1 text-sn-delete-red">
        <i class="fas fa-exclamation-triangle"></i>
        {{ i18n.t('projects.reports.index.error') }}
        <span v-if="docx.preview_url" class="text-sn-black">|</span>
        <a v-if="docx.preview_url" href="#"
           class="file-preview-link flex items-center gap-1
                  docx hover:no-underline whitespace-nowrap"
           :data-preview-url="docx.preview_url">
          {{ i18n.t('projects.reports.index.previous_docx') }}
        </a>
      </span>
    </template>
    <span v-else-if="docx.processing" class="processing docx">
      {{ i18n.t('projects.reports.index.generating') }}
    </span>
    <template v-else-if="docx.preview_url">
      <a v-if="docx.preview_url" href="#"
          class="file-preview-link flex items-center gap-1
                docx hover:no-underline whitespace-nowrap"
          :data-preview-url="docx.preview_url">
        <i class="sn-icon sn-icon-file-word"></i>
        {{ i18n.t('projects.reports.index.docx') }}
      </a>
    </template>
    <a v-else class="hidden group-hover:!block" href="#" @click.prevent="generate">
      {{ i18n.t('projects.reports.index.generate') }}
    </a>
  </div>
</template>

<script>
import axios from '../../../packs/custom_axios.js';

export default {
  name: 'DocxRenderer',
  props: {
    params: {
      required: true
    }
  },
  data() {
    return {
      docx: this.params.data.docx_file
    };
  },
  mounted() {
    if (this.docx.processing) {
      setTimeout(this.checkStatus, 3000);
    }
  },
  watch: {
    'params.data.docx_file': {
      handler: function (val) {
        this.docx = val;
        if (val?.processing) {
          setTimeout(this.checkStatus, 3000);
        }
      },
      deep: true
    }
  },
  methods: {
    generate() {
      axios.post(this.params.data.urls.generate_docx)
        .then(() => {
          this.docx.processing = true;
          this.checkStatus();
        });
    },
    checkStatus() {
      axios.get(this.params.data.urls.status)
        .then((response) => {
          this.docx = response.data.data.attributes.docx_file;
          if (this.docx.processing) {
            setTimeout(this.checkStatus, 3000);
          }
        });
    }
  }
};
</script>
