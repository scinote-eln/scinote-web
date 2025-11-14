<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <form @submit.prevent="submit">
        <div class="modal-content">
          <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
              <i class="sn-icon sn-icon-close"></i>
            </button>
            <h4 class="modal-title truncate !block">
              {{ this.i18n.t('protocols.repository_rows.index.assign_item') }}
            </h4>

          </div>
          <div class="modal-body">
            <p class="mb-4">
              {{ this.i18n.t('protocols.repository_rows.assign_modal.description') }}
            </p>
            <RowSelector @change="this.rowId = $event" class="mb-4"></RowSelector>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.cancel') }}</button>
            <button class="btn btn-primary" type="submit" :disabled="!validObject">
              {{ this.i18n.t('protocols.repository_rows.index.assign_item') }}
            </button>
          </div>
        </div>
      </form>
    </div>
  </div>
</template>

<script>
/* global HelperModule */

import modalMixin from '../../shared/modal_mixin';
import RowSelector from '../../shared/repository_row_selector.vue';

export default {
  name: 'RowAssignModal',
  mixins: [modalMixin],
  computed: {
  },
  data() {
    return {
      rowId: null
    };
  },
  components: {
    RowSelector,
  },
  computed: {
    validObject() {
      return this.rowId && this.rowId > 0;
    },
  },
  methods: {
    submit() {
      this.$emit('assign', this.rowId);
    }
  }
};
</script>
