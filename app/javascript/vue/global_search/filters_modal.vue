<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <form @submit.prevent="submit">
        <div class="modal-content !pb-2.5">
          <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
              <i class="sn-icon sn-icon-close"></i>
            </button>
            <h4 class="modal-title truncate !block" id="edit-project-modal-label">
              {{ i18n.t('search.filters.title') }}
            </h4>
          </div>
          <div class="modal-body !pb-0">
            <p class="text-sn-dark-grey">
              {{ i18n.t('search.filters.sub_title') }}
            </p>
            <Filters
              :teams-url="teamsUrl"
              :users-url="usersUrl"
              :filters="filters"
              :currentTeam="currentTeam"
              @search="(newFilters) => { this.$emit('search', newFilters); }"
              @close="close" />
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
