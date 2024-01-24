<template>
  <div class="pdf-viewer" :class="{ 'blocked': pdf.blocked }">
    <div class="page-container">
      <div class="layers-container">
        <canvas class="pdf-canvas" :class="{ 'ready': !pdf.blocked }"
          :data-pdf-url="pdf.url"
          :data-pdf-worker-url="pdf.worker_url"
        ></canvas>
        <div class="textLayer"></div>
      </div>
    </div>
    <div class="pdf-toolbar">
      <button class="btn btn-light icon-btn prev-page">
        <i class="sn-icon sn-icon-arrow-left"></i>
      </button>
      <div class="page-counter sci-input-container">
        <input type="text" class="sci-input-field current-page" value=1>
        {{ i18n.t('pdf_preview.pages.of') }}
        <span class="total-page">...</span>
      </div>
      <button class="btn btn-light icon-btn next-page">
        <i class="sn-icon sn-icon-arrow-right"></i>
      </button>
      <div class="divider"></div>
      <div class="zoom-page">
        <select class="zoom-page-selector">
          <option value="auto">{{ i18n.t('pdf_preview.fit_to_screen') }}</option>
          <option v-for="i in Array.from(Array(12).keys())"
                  :selected="(i + 1) * 25 == 100"
                  :value="((i + 1) * 0.25).toString().replaceAll(/\.?0+$/g, '')"
                  :key="i">
            {{(i + 1) * 25}}%
          </option>
        </select>
      </div>
      <div class="sci-btn-group">
        <button class="btn btn-light icon-btn zoom-out">
          <i class="sn-icon sn-icon-search-minus"></i>
        </button>
        <button class="btn btn-light icon-btn zoom-in">
          <i class="sn-icon sn-icon-search-plus"></i>
        </button>
      </div>
    </div>
    <div class="blocked-screen">
      <img :src="blockedIcon">
      <p class="title">{{ i18n.t('pdf_previepw.blocked.title') }}</p>
      <p class="description">{{ i18n.t('pdf_preview.blocked.description') }}</p>
      <button class="btn btn-primary load-blocked-pdf">
        <i class="fas fa-cloud-download-alt"></i>
        {{ i18n.t('pdf_preview.blocked.submit_button') }}
      </button>
    </div>
  </div>
</template>

<script>
import blockedIcon from '../images/pdf_js/blocked.svg';

export default {
  name: 'PdfViewer',
  props: {
    pdf: { type: Object, required: true }
  },
  data() {
    return {
      blockedIcon,
      value: ''
    };
  },
  mounted() {
    // from legacy code in app/assets/javascripts/sitewide/pdf_preview.js
    PdfPreview.initCanvas();
  },
  methods: {
  }
};
</script>
