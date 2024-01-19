<template>
  <div ref="modal" @keydown.esc="cancel" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog modal-sm" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close"><i class="sn-icon sn-icon-close"></i></button>
          <h4 class="modal-title">
            {{ i18n.t('label_templates.show.insert_dropdown.logo_modal.title') }}
          </h4>
        </div>
        <div class="modal-body">
          <p>{{ i18n.t('label_templates.show.insert_dropdown.logo_modal.description') }}</p>
          <div class="dimensions-container">
            <div class="sci-input-container">
              <label>{{ i18n.t('label_templates.show.insert_dropdown.logo_modal.width', {unit: unit}) }}</label>
              <input type="number" min="0" v-model="width" class="sci-input-field" @change="updateHeight">
            </div>
            <img src="/images/icon_small/link.svg"/>
            <div class="sci-input-container">
              <label>{{ i18n.t('label_templates.show.insert_dropdown.logo_modal.height', {unit: unit}) }}</label>
              <input type="number" min="0" v-model="height" class="sci-input-field" @change="updateWidth">
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn btn-secondary" @click="cancel">{{ i18n.t('general.cancel') }}</button>
          <button class="btn btn-primary" @click="confirm">{{ i18n.t('label_templates.show.insert_dropdown.logo_modal.insert') }}</button>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
export default {
  name: 'logoInsertModal',
  props: {
    unit: { type: String, required: true },
    density: { type: Number, required: true },
    dimension: { type: Array, required: true }
  },
  data() {
    return {
      width: 0,
      height: 0,
      ratio: 1
    };
  },
  mounted() {
    $(this.$refs.modal).modal('show');
    $(this.$refs.modal).on('hidden.bs.modal', () => {
      this.$emit('cancel');
    });
    this.width = this.dimension[0] / this.density;
    this.height = this.dimension[1] / this.density;
    if (this.unit == 'in') {
      this.width /= 25.4;
      this.height /= 25.4;
    }

    this.width = Math.round(this.width * 100) / 100;
    this.height = Math.round(this.height * 100) / 100;
    this.ratio = this.dimension[0] / this.dimension[1];
  },
  methods: {
    updateHeight() {
      this.height = Math.round(this.width * 10 / this.ratio) / 10;
    },
    updateWidth() {
      this.width = Math.round(this.height * this.ratio * 10) / 10;
    },
    confirm() {
      this.$emit('insert:tag', { tag: `{{LOGO, ${this.unit}, ${this.width}, ${this.height}}}` });
      $(this.$refs.modal).modal('hide');
    },
    cancel() {
      $(this.$refs.modal).modal('hide');
    }
  }
};
</script>
