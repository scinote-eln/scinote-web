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
          <div v-if="editMode" class="sci-input-container-v2 !h-40">
            <textarea
              v-model="textValue"
              ref="input"
              class="sci-input-field w-full "
              data-e2e="e2e-TX-invItems-addTextModal-textArea"
            ></textarea>
          </div>
          <div v-else ref="textContainer" class="[&_.atwho-user-container]:!whitespace-normal whitespace-pre-wrap break-words">
            <span data-e2e="e2e-TX-invItems-addTextModal-textArea">{{ textValue }}</span>
          </div>
        </div>
        <div class="modal-footer">
          <template v-if="editMode">
            <button
              type="button"
              class="btn btn-secondary"
              @click="cancelEdit"
              data-e2e="e2e-BT-invItems-addTextModal-cancel"
            >{{ i18n.t('general.cancel') }}</button>
            <button
              type="button"
              class="btn btn-primary"
              @click="saveCell"
              data-e2e="e2e-BT-invItems-addTextModal-save"
            >{{ i18n.t('general.save') }}</button>
          </template>
          <template v-else>
            <button
              type="button"
              class="btn btn-secondary"
              data-dismiss="modal"
              data-e2e="e2e-BT-invItems-addTextModal-cancel"
            >{{ i18n.t('general.close') }}</button>
            <button
              v-if="canManage"
              type="button"
              class="btn btn-primary"
              @click="startEdit"
              data-e2e="e2e-BT-invItems-addTextModal-edit"
            >{{ i18n.t('general.edit') }}</button>
          </template>
        </div>
      </div>
    </div>
  </div>
</template>

<script>

import modalMixin from '../../shared/modal_mixin';

// Opens in view mode so Smart Annotations stay clickable; edit is one click away,
// like the project/experiment description modal. Empty cells open straight in edit mode.
export default {
  name: 'TextCellModal',
  props: {
    colDef: Object,
    row: Object
  },
  data: () => ({
    textValue: '',
    editMode: false
  }),
  computed: {
    savedValue() {
      return this.row[this.colDef.field]?.value?.edit || '';
    },
    canManage() {
      return !!this.row.permissions?.manage;
    }
  },
  mounted() {
    this.textValue = this.savedValue;

    if (this.canManage && this.savedValue === '') {
      this.startEdit();
    } else {
      this.renderView();
    }
  },
  mixins: [modalMixin],
  methods: {
    renderView() {
      this.$nextTick(() => {
        if (this.$refs.textContainer) {
          window.renderElementSmartAnnotations(this.$refs.textContainer, 'span');
        }
      });
    },
    startEdit() {
      this.editMode = true;
      this.$nextTick(() => {
        SmartAnnotation.init($(this.$refs.input), false);
        this.$refs.input.focus();
      });
    },
    cancelEdit() {
      if (this.savedValue === '') {
        this.close();
        return;
      }

      this.textValue = this.savedValue;
      this.editMode = false;
      this.renderView();
    },
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
