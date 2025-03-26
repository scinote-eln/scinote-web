<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <form @submit.prevent="submit">
        <div class="modal-content">
          <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
              <i class="sn-icon sn-icon-close"></i>
            </button>
            <h4 class="modal-title truncate !block" >
              {{  i18n.t('forms.show.select_items') }}
            </h4>
          </div>
          <div class="modal-body">
            <p>
              {{  i18n.t('forms.show.select_items_description') }}
            </p>
            <RepositoryRowSelector
              :multiple="true"
              :preSelectedRepository="selectedRepository"
              :preSelectedRows="selectedRows"
              @change="selectedRows = $event"
              @repositoryChange="changeSelectedInventory"
            />
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-dismiss="modal">{{ i18n.t('general.cancel') }}</button>
            <button type="button" class="btn btn-primary" @click="save"> {{  i18n.t('forms.show.select_items') }}</button>
          </div>
        </div>
      </form>
    </div>
  </div>
</template>

<script>

import modalMixin from '../../../shared/modal_mixin.js';
import RepositoryRowSelector from '../../../shared/repository_row_selector.vue';

export default {
  name: 'RowSelectorModal',
  props: {
    repository: Number,
    rows: Array
  },
  mixins: [modalMixin],
  components: {
    RepositoryRowSelector
  },
  data() {
    return {
      selectedRepository: null,
      selectedRows: []
    };
  },
  created() {
    this.selectedRepository = this.repository;
    this.selectedRows = this.rows;
  },
  mounted() {
  },
  methods: {
    changeSelectedInventory(repository) {
      this.selectedRepository = repository;
      this.selectedRows = [];
    },
    save() {
      this.$emit('save', this.selectedRepository, this.selectedRows);
    }
  }
};
</script>
