<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <form @submit.prevent="submit">
        <div class="modal-content !pb-2.5" data-e2e="e2e-MD-globalSearch-filters">
          <div class="modal-header flex-wrap">
            <button type="button" class="close" data-dismiss="modal" aria-label="Close" data-e2e="e2e-BT-globalSearch-filters-close">
              <i class="sn-icon sn-icon-close"></i>
            </button>
            <h4 class="modal-title truncate !block" id="edit-project-modal-label" data-e2e="e2e-TX-globalSearch-filters-title">
              {{ i18n.t('search.filters.title') }}
            </h4>
            <div class="basis-full" data-e2e="e2e-TX-globalSearch-filters-subtitle">
              {{ i18n.t('search.filters.sub_title') }}
            </div>
          </div>
          <div class="modal-body !pb-0 !pt-2.5">
            <Filters
              :teams-url="teamsUrl"
              :users-url="usersUrl"
              :filters="filters"
              :currentTeam="currentTeam"
              @search="(newFilters) => { this.$emit('search', newFilters); }"
              @cancel="close" />
          </div>
        </div>
      </form>
    </div>
  </div>
</template>

<script>
import modalMixin from '../shared/modal_mixin';
import Filters from './filters.vue';

export default {
  name: 'FiltersModal',
  props: {
    teamsUrl: String,
    usersUrl: String,
    filters: Object,
    currentTeam: Number || String
  },
  components: {
    Filters
  },
  mixins: [modalMixin]
};
</script>
