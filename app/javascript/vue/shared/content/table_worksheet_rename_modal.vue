<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title truncate !block">
            {{ i18n.t(`scinote.native_tables.rename_worksheet`) }}
          </h4>
        </div>
        <div class="modal-body">
          <div class="sci-input-container-v2" :class="{ 'error': !validName }">
            <input type="text" ref="inputField" v-model="new_worksheet_name" class="sci-input-field" />
          </div>
          <span v-if="!validName" class="sci-error-text">
            {{ i18n.t("scinote.native_tables.worksheet_name_error", { length: minLength }) }}
          </span>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary"  data-dismiss="modal">{{ i18n.t('general.cancel') }}</button>
          <button class="btn btn-primary" type="button" @click.prevent="save" :disabled="!validName">
            {{ i18n.t('general.save') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import modalMixin from '../modal_mixin';

export default {
  name: 'WorksheetRenameModal',
  mixins: [modalMixin],
  props: {
    worksheet_name: String
  },
  data() {
    return {
      new_worksheet_name: this.worksheet_name
    };
  },
  computed: {
    minLength() {
      return GLOBAL_CONSTANTS.NAME_MIN_LENGTH;
    },
    validName() {
      return this.new_worksheet_name.length >= this.minLength;
    }
  },
  methods: {
    save() {
      this.$emit('confirm', this.new_worksheet_name);
    }
  }
};
</script>
