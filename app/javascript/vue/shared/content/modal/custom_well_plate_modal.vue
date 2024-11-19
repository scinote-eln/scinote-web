<template>
  <div ref="modal" @keydown.esc="cancel" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" @click="cancel" aria-label="Close"><i class="sn-icon sn-icon-close"></i></button>
          <h4 class="modal-title">
            {{ i18n.t('protocols.steps.modals.custom_well_plate.title') }}
          </h4>
        </div>
        <div class="modal-body">
          <div class="mb-6">
            <label class="sci-label">
              {{ i18n.t('protocols.steps.modals.custom_well_plate.name_label') }}
            </label>
            <div class="sci-input-container-v2">
              <input
                type="text"
                v-model="plateName"
                :placeholder="i18n.t('protocols.steps.modals.custom_well_plate.name_placeholder')"
              >
            </div>
          </div>
          <div class="flex flex-col">
            <p>{{ i18n.t('protocols.steps.modals.custom_well_plate.dimension_label') }}</p>
            <div class="flex items-center gap-2">
              <div class="sci-input-container-v2 !w-28">
                <input type="number"  v-model="dimensions[0]" min="1" max="48">
              </div>
              <i class="sn-icon sn-icon-close-small"></i>
              <div class="sci-input-container-v2 !w-28">
                <input type="number"  v-model="dimensions[1]" min="1" max="48">
              </div>
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn btn-secondary" @click="cancel">{{ i18n.t('general.cancel') }}</button>
          <button class="btn btn-primary" @click="confirm">{{ i18n.t('general.insert')}}</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'CustomWellPlateModal',
  data() {
    return {
      plateName: '',
      dimensions: [1, 1]
    };
  },
  mounted() {
    $(this.$refs.modal).modal('show');
    $(this.$refs.modal).on('hidden.bs.modal', () => {
      this.$emit('cancel');
    });
  },
  methods: {
    confirm() {
      $(this.$refs.modal).modal('hide');
      this.$emit('create:table', this.dimensions, this.plateName);
    },
    cancel() {
      $(this.$refs.modal).modal('hide');
    }
  }
};
</script>
