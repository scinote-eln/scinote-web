<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title truncate !block">
            {{ i18n.t(`scinote.native_tables.${smartAnnotationMode}_sa`) }}
          </h4>
        </div>
        <div class="modal-body">
          <div class="sci-input-container-v2">
            <input type="text" ref="inputField" :value="new_sa_data" class="sci-input-field py-0 leading-10" />
          </div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.cancel') }}</button>
          <button class="btn btn-primary" type="button" @click.prevent="save">
            {{ i18n.t('general.save') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
/* global SmartAnnotation */
import modalMixin from '../modal_mixin';

export default {
  name: 'SmartAnnotationModal',
  mixins: [modalMixin],
  props: {
    sa_data: String,
    smartAnnotationMode: String
  },
  mounted() {
    SmartAnnotation.init($(this.$refs.inputField), false, document.querySelector('.my-module-content')?.dataset?.taskId);
  },
  data() {
    return {
      new_sa_data: this.sa_data
    };
  },
  methods: {
    save() {
      this.new_sa_data = this.$refs.inputField.value;
      this.$emit('confirm', this.new_sa_data);
    }
  }
};
</script>
