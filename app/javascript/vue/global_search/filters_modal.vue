<template>
  <div ref="modal" class="modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
      <form @submit.prevent="submit">
        <div class="modal-content !pb-2.5">
          <div class="modal-header flex-wrap">
            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
              <i class="sn-icon sn-icon-close"></i>
            </button>
            <h4 class="modal-title truncate !block" id="edit-project-modal-label">
              {{ i18n.t('search.filters.title') }}
            </h4>
            <div class="basis-full">
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
