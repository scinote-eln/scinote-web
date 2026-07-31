<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title truncate !block" id="edit-project-modal-label" :title="colDef.headerName">
            {{ colDef.headerName }}
          </h4>
        </div>
        <div class="modal-body">
          <div v-if="row.permissions.manage" class="sci-input-container-v2 !h-40">
            <textarea v-model="textValue" ref="input" class="sci-input-field w-full "></textarea>
          </div>
          <div v-else ref="textContainer" class="[&_.atwho-user-container]:!whitespace-normal whitespace-pre-wrap">
            <span v-html="textValue"></span>
          </div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.close') }}</button>
          <button v-if="row.permissions.manage" type="button" class="btn btn-primary" @click="saveCell">{{ i18n.t('general.save') }}</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>

import modalMixin from '../../shared/modal_mixin';

export default {
  name: 'TextCellModal',
  props: {
    colDef: Object,
    row: Object
  },
  data: () => ({
    textValue: ''
  }),
  mounted() {
    this.textValue = this.row[this.colDef.field]?.value?.edit || '';

    this.$nextTick(() => {
      if (this.$refs.textContainer) {
        window.renderElementSmartAnnotations(this.$refs.textContainer, 'span');
      }
      if (this.$refs.input) {
        SmartAnnotation.init($(this.$refs.input), false);
        this.$refs.input.focus();
      }
    });
  },
  mixins: [modalMixin],
  methods: {
    saveCell() {
      this.$emit(
        'updateCell',
        this.row,
        this.colDef,
        this.$refs.input.value
      );
    }
  }
};
</script>
