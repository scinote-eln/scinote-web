<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <i class="sn-icon sn-icon-close"></i>
          </button>
          <h4 class="modal-title truncate !block" id="filters-modal-label">
            {{ i18n.t('repositories.show.filters.title') }}
          </h4>
        </div>
        <div class="modal-body">
          <label class="sci-label">
            {{ i18n.t('repositories.show.filters.filter_name') }}
          </label>
          <div class="sci-input-container-v2">
            <input type="text" class="sci-input-field" v-model="filterName">
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn btn-secondary clear-filters-btn prevent-shrink ml-auto" @click="close">
            {{ i18n.t('general.cancel') }}
          </button>
          <button class="btn btn-primary apply-button prevent-shrink" @click="saveFilter">
            {{ i18n.t('repositories.show.filters.save_filter') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>

import modalMixin from '../../shared/modal_mixin';
import axios from '../../../packs/custom_axios.js';

import {
  repository_repository_table_filters_path
 } from '../../../routes.js';

export default {
  name: 'SaveFitlerModal',
  props: {
    activeFilter: Object,
    repositoryId: Number
  },
  data: () => ({
    filterName: '',
  }),
  mixins: [modalMixin],
  methods: {
    saveFilter() {
      const params = {
        repository_table_filter: {
          name: this.filterName,
          repository_table_filter_elements_json: JSON.stringify(this.activeFilter.filters)
        }
      }
      axios.post(repository_repository_table_filters_path(this.repositoryId), params).then((response) => {
        this.$emit('filterSaved', response.data.data)
        this.close()
      }).catch(() => {
        HelperModule.flashAlertMsg(I18n.t('general.error'), 'danger');
      })
    },
  }
};
</script>
