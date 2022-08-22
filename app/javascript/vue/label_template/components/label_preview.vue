<template>
  <div ref="labelPreview" class="label-preview">
    <div class="label-preview__header">
      <div class="title">
        {{ i18n.t('label_templates.show.preview_title') }}
      </div>
      <div class="label-preview__options-button" @click="optionsOpen = !optionsOpen">
        {{ i18n.t('label_templates.label_preview.options') }}

        <i class="fas" :class="{ 'fa-angle-down': !optionsOpen, 'fa-angle-up': optionsOpen }"></i>
      </div>
    </div>
    <div class="label-preview__controls" :class="{'open': optionsOpen}">
      <div class="label-preview__controls__units">
        <div class="sci-input-container">
          <label>{{ i18n.t('label_templates.label_preview.units') }}</label>
          <DropdownSelector
            :disableSearch="true"
            :options="[{ value: 'in', label: i18n.t(`label_templates.label_preview.in`) }, { value: 'mm', label: i18n.t(`label_templates.label_preview.mm`) }]"
            :selectorId="'UnitSelector'"
            :selectedValue="unit"
            @dropdown:changed="updateUnit" />
        </div>
      </div>
      <div class="label-preview__controls__size">
        <div class="sci-input-container">
          <label>{{ i18n.t('label_templates.label_preview.height') }}</label>
          <input v-model="height" type="text" class="sci-input-field" />
        </div>
        <div class="sci-input-container">
          <label>{{ i18n.t('label_templates.label_preview.width') }}</label>
          <input v-model="width" type="text" class="sci-input-field" />
        </div>
        <div class="sci-input-container">
          <label>{{ i18n.t('label_templates.label_preview.density') }}</label>
          <DropdownSelector
              :key="unit"
              :disableSearch="true"
              :options="unit === 'in' ? DPI_RESOLUTION_OPTIONS : DPMM_RESOLUTION_OPTIONS"
              :selectorId="'DensitySelector'"
              :selectedValue="density"
              @dropdown:changed="updateDensity" />
        </div>
      </div>
      <div class="label-preview__refresh" @click="refreshPreview">
        <i class="fas fa-sync"></i>
        {{ i18n.t('label_templates.label_preview.refresh_preview') }}
      </div>
    </div>
    <div v-if="base64Image" class="label-preview__image">
      <img :src="`data:image/png;base64,${base64Image}`" />
    </div>
  </div>
</template>

 <script>
  const DPI_RESOLUTION_OPTIONS = [
    { value: 6, label: '6 dpi' },
    { value: 8, label: '8 dpi', selected: true },
    { value: 12, label: '12 dpi'},
    { value: 24, label: '24 dpi' }
  ]

  const DPMM_RESOLUTION_OPTIONS = [
    { value: 6, label: '152 dpmm (6 dpi)' },
    { value: 8, label: '203 dpmm (8 dpi)', selected: true },
    { value: 12, label: '300 dpmm (12 dpi)' },
    { value: 24, label: '600 dpmm (24 dpi)' }
  ]

  import DropdownSelector from 'vue/shared/dropdown_selector.vue'

  export default {
    name: 'LabelPreview',
    components: { DropdownSelector },
    props: {
      zpl: { type: String, required: true },
      previewUrl: { type: String, required: true }
    },
    data() {
      return {
        DPMM_RESOLUTION_OPTIONS,
        DPI_RESOLUTION_OPTIONS,
        optionsOpen: false,
        width: null,
        height: null,
        unit: 'in',
        density: 8,
        base64Image: null,
        imageStyle: ''
      }
    },
    mounted() {
      this.refreshPreview();
    },
    computed: {
      widthMm() {
        return this.unit === 'in' ? this.width * 25.4 : this.width;
      },
      heightMm() {
        return this.unit === 'in' ? this.height * 25.4 : this.height;
      }
    },
    methods: {
      refreshPreview() {
        $.ajax({
          url: this.previewUrl,
          type: 'GET',
          data: {
            zpl: this.zpl,
            width: this.widthMm,
            height: this.heightMm,
            density: this.density
          },
          success: (result) => {
            this.base64Image = result.base64_preview;
          }
        });
      },
      updateUnit(unit) {
        this.unit = unit;
      },
      updateDensity(density) {
        this.density = density;
      }
    }
  }
 </script>
