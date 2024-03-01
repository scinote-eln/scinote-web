<template>
  <div ref="labelPreview" class="label-preview">
    <div v-if="!viewOnly" class="label-preview__header">
      <div class="title">
        {{ i18n.t('label_templates.show.preview_title') }}
      </div>
      <div class="label-preview__options-button" @click="optionsOpen = !optionsOpen">
        {{ i18n.t('label_templates.label_preview.options') }}

        <i class="fas" :class="{ 'fa-chevron-down': !optionsOpen, 'fa-chevron-up': optionsOpen }"></i>
      </div>
    </div>
    <div v-if="!viewOnly" class="label-preview__controls" :class="{'open': optionsOpen}">
      <div v-if="canManage">
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
            <input v-model="height" type="number" class="sci-input-field"
                  @change="$emit('height:update', (unit === 'in' ? height * 25.4 : height))"  />
          </div>
          <div class="sci-input-container">
            <label>{{ i18n.t('label_templates.label_preview.width') }}</label>
            <input v-model="width" type="number" class="sci-input-field"
                  @change="$emit('width:update', (unit === 'in' ? width * 25.4 : width))" />
          </div>
          <div class="sci-input-container">
            <label>{{ i18n.t('label_templates.label_preview.density') }}</label>
            <DropdownSelector
                v-if="density"
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
      <div v-else>
        <label>{{ i18n.t('label_templates.label_preview.units') }}</label>
        <DropdownSelector
          :disableSearch="true"
          :options="[{ value: 'in', label: i18n.t(`label_templates.label_preview.in`) }, { value: 'mm', label: i18n.t(`label_templates.label_preview.mm`) }]"
          :selectorId="'UnitSelector'"
          :selectedValue="unit"
          @dropdown:changed="updateUnit" />

        <div>{{ i18n.t('label_templates.label_preview.height') }}: {{ height }} {{ unit }} </div>
        <div>{{ i18n.t('label_templates.label_preview.width') }}: {{ width }} {{ unit }} </div>
        <div>{{ i18n.t('label_templates.label_preview.density') }}: {{ densityLabel() }}</div>
      </div>
    </div>
    <div v-if="base64Image" class="label-preview__image">
      <img :src="`data:image/png;base64,${base64Image}`" />
    </div>
    <div class="label-preview__error" v-html="i18n.t('label_templates.label_preview.error_html')"
         v-else-if="base64Image != null && base64Image.length === 0">
    </div>

  </div>
</template>

<script>

const DPI_RESOLUTION_OPTIONS = [
  { value: 6, label: '152 dpi' },
  { value: 8, label: '203 dpi' },
  { value: 12, label: '300 dpi' },
  { value: 24, label: '600 dpi' }
];

const DPMM_RESOLUTION_OPTIONS = [
  { value: 6, label: '6 dpmm (152 dpi)' },
  { value: 8, label: '8 dpmm (203 dpi)' },
  { value: 12, label: '12 dpmm (300 dpi)' },
  { value: 24, label: '24 dpmm (600 dpi)' }
];

import DropdownSelector from '../../shared/legacy/dropdown_selector.vue'

export default {
  name: 'LabelPreview',
  components: { DropdownSelector },
  props: {
    template: { type: Object, required: true },
    zpl: { type: String, required: true },
    previewUrl: { type: String, required: true },
    viewOnly: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      DPMM_RESOLUTION_OPTIONS,
      DPI_RESOLUTION_OPTIONS,
      optionsOpen: false,
      width: this.template.attributes.unit == 'in' ? this.template.attributes.width_mm / 25.4 : this.template.attributes.width_mm,
      height: this.template.attributes.unit == 'in' ? this.template.attributes.height_mm / 25.4 : this.template.attributes.height_mm,
      unit: this.template.attributes.unit,
      density: this.template.attributes.density,
      base64Image: null,
      imageStyle: ''
    };
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
    },
    canManage() {
      return this.template.attributes.urls.update;
    }
  },
  watch: {
    unit() {
      this.setDefaults();
    },
    zpl() {
      this.refreshPreview();
    },
    template() {
      this.unit = this.template.attributes.unit;
      this.width = this.template.attributes.unit == 'in' ? this.template.attributes.width_mm / 25.4 : this.template.attributes.width_mm;
      this.height = this.template.attributes.unit == 'in' ? this.template.attributes.height_mm / 25.4 : this.template.attributes.height_mm;
      this.density = this.template.attributes.density;
    }
  },
  methods: {
    setDefaults() {
      !this.unit && (this.unit = 'in');
      !this.density && (this.density = 12);
      !this.width && (this.width = this.unit === 'in' ? 2 : 50.8);
      !this.height && (this.height = this.unit === 'in' ? 1 : 25.4);
    },
    recalculateUnits() {
      if (this.unit === 'in') {
        this.width /= 25.4;
        this.height /= 25.4;
      } else {
        this.width *= 25.4;
        this.height *= 25.4;
      }
    },
    refreshPreview() {
      if (this.zpl.length === 0) return;

      this.base64Image = null;

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
          if (this.base64Image.length > 0) {
            this.$emit('preview:valid');
          } else {
            this.$emit('preview:invalid');
          }
        },
        error: (result) => {
          this.base64Image = '';
          this.$emit('preview:invalid');
        }

      });
    },
    updateUnit(unit) {
      if (this.unit === unit) return;
      this.unit = unit;
      this.recalculateUnits();
      this.$emit('unit:update', this.unit);
    },
    updateDensity(density) {
      this.density = density;
      this.$emit('density:update', this.density);
    },
    densityLabel() {
      const resolutions = this.unit === 'in' ? DPI_RESOLUTION_OPTIONS : DPMM_RESOLUTION_OPTIONS;
      return resolutions.find((element) => element.value === this.density).label;
    }
  }
};
</script>
