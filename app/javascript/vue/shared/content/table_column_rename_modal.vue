<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title truncate !block">
            {{ i18n.t(`scinote.native_tables.rename_column`) }}
          </h4>
        </div>
        <div class="modal-body">
          <div class="sci-input-container-v2">
            <input type="text" ref="inputField" v-model="new_column_name" class="sci-input-field" />
          </div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary"  data-dismiss="modal">{{ i18n.t('general.cancel') }}</button>
          <button class="btn btn-primary" type="button" @click.prevent="save">
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
  name: 'ColumnRenameModal',
  mixins: [modalMixin],
  props: {
    column_name: String
  },
  data() {
    return {
      new_column_name: this.column_name
    };
  },
  methods: {
    save() {
      this.$emit('confirm', this.new_column_name);
    }
  }
};
</script>
