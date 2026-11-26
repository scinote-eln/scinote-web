<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content" data-e2e="e2e-MD-invItems-addText">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close" data-e2e="e2e-BT-invItems-addTextModal-close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4
            class="modal-title truncate !block"
            id="edit-project-modal-label"
            :title="colDef.headerName"
            data-e2e="e2e-TX-invItems-addTextModal-title"
          >
            {{ colDef.headerName }}
          </h4>
        </div>
        <div class="modal-body">
          <div v-if="editMode"
               class="sci-input-container-v2 !h-40"
               :class="{ error: fieldError }"
               :data-error="fieldError">
            <textarea
              v-model="textValue"
              ref="input"
              @blur="touched = true"
              class="sci-input-field w-full "
              data-e2e="e2e-TX-invItems-addTextModal-textArea"
            ></textarea>
          </div>
          <div v-else ref="textContainer" class="[&_.atwho-user-container]:!whitespace-normal whitespace-pre-wrap">
            <span data-e2e="e2e-TX-invItems-addTextModal-textArea">{{ textValue }}</span>
          </div>
        </div>
        <div class="modal-footer">
          <button
            v-if="editMode"
            type="button"
            class="btn btn-secondary"
            @click="cancelEdit"
            data-e2e="e2e-BT-invItems-addTextModal-cancel"
          >{{ i18n.t('general.cancel') }}</button>
          <button
            v-else
            type="button"
            class="btn btn-secondary"
            data-dismiss="modal"
            data-e2e="e2e-BT-invItems-addTextModal-cancel"
          >{{ i18n.t('general.close') }}</button>
          <button
            v-if="canManage && !editMode"
            type="button"
            class="btn btn-primary"
            @click="startEdit"
            data-e2e="e2e-BT-invItems-addTextModal-edit"
          >{{ i18n.t('general.edit') }}</button>
          <button
            v-if="editMode"
            type="button"
            class="btn btn-primary"
            @click="saveCell"
            data-e2e="e2e-BT-invItems-addTextModal-save"
          >{{ i18n.t('general.save') }}</button>
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
    row: Object,
    errorMessage: { type: String, default: null }
  },
  data: () => ({
    textValue: '',
    touched: false,
    rejectedValue: null,
    originalValue: '',
    editMode: false
  }),
  watch: {
    errorMessage(newVal) {
      this.rejectedValue = newVal ? this.textValue.trim().toLowerCase() : null;
    }
  },
  computed: {
    canManage() {
      return this.row.permissions?.manage || false;
    },
    mandatory() {
      const { isMandatory, mandatory } = this.colDef.cellRendererParams || {};

      return isMandatory ? !!isMandatory() : !!mandatory;
    },
    isEmpty() {
      return this.textValue.trim() === '';
    },
    showError() {
      return this.mandatory && this.touched && this.isEmpty;
    },
    showUniqueError() {
      return !!this.errorMessage && this.rejectedValue !== null
        && this.textValue.trim().toLowerCase() === this.rejectedValue;
    },
    fieldError() {
      if (this.showError) return this.i18n.t('repositories.mandatory_column.field_error');
      if (this.showUniqueError) return this.errorMessage;

      return null;
    }
  },
  created() {
    this.originalValue = this.row[this.colDef.field]?.value?.edit || '';
    this.textValue = this.originalValue;
    this.editMode = this.canManage && this.originalValue === '';
  },
  mounted() {
    this.$nextTick(this.initContent);
  },
  mixins: [modalMixin],
  methods: {
    initContent() {
      if (this.$refs.textContainer) {
        window.renderElementSmartAnnotations(this.$refs.textContainer, 'span');
      }
      if (this.$refs.input) {
        SmartAnnotation.init($(this.$refs.input), false);
        this.$refs.input.focus();
      }
    },
    startEdit() {
      this.editMode = true;
      this.$nextTick(this.initContent);
    },
    cancelEdit() {
      if (this.originalValue === '') {
        this.close();
        return;
      }

      this.textValue = this.originalValue;
      this.editMode = false;
      this.$nextTick(this.initContent);
    },
    saveCell() {
      this.textValue = this.$refs.input.value;
      this.touched = true;
      if (this.showError && this.row.id) return;
      if (this.showUniqueError) return;

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
