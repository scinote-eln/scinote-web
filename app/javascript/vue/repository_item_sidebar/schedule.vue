<template>
  <div v-if="repositoryRow">
    <div class="flex items-center gap-4">
      <h4 data-e2e="e2e-TX-itemCard-schedule-title">{{ i18n.t('repositories.equipment_booking.title') }}</h4>
      <button v-if="repositoryRow.permissions.can_manage &&
                    repositoryRow.equipment_booking.enabled &&
                    !repositoryRow.default_columns.archived"
              class="btn btn-light ml-auto"
              @click="createEvent = true">
        {{ i18n.t('repositories.equipment_booking.create_event') }}
      </button>
    </div>
    <template v-if="!repositoryRow.default_columns.archived">
      <div v-if="futureEvents.length > 0" class="mt-4">
        <h5 class="!text-sm">{{ i18n.t('repositories.equipment_booking.upcoming_events') }}</h5>
        <div v-for="event in futureEvents" :key="event.id" class="mb-2 flex items-center">
          <span class="truncate" :title="event.attributes.name">{{ event.attributes.name }}</span>:
          <span class="grow shrink-0 ml-1">{{ event.attributes.start_at_formatted }} - {{ event.attributes.end_at_formatted }}</span>
        </div>
        <div v-if="futurePage" class="cursor-pointer text-sn-science-blue" @click="fetchEvents('future', futurePage)">
          {{ i18n.t('repositories.equipment_booking.show_more') }}
        </div>
      </div>
      <div v-if="pastEvents.length > 0" class="mt-4">
        <h5 class="!text-sm">{{ i18n.t('repositories.equipment_booking.past_events') }}</h5>
        <div v-for="event in pastEvents" :key="event.id" class="mb-2 flex items-center text-sn-grey-700">
          <span class="truncate" :title="event.attributes.name">{{ event.attributes.name }}</span>:
          <span class="grow shrink-0 ml-1">{{ event.attributes.start_at_formatted }} - {{ event.attributes.end_at_formatted }}</span>
        </div>
        <div v-if="pastPage" class="cursor-pointer text-sn-blue" @click="fetchEvents('past', pastPage)">
          {{ i18n.t('repositories.equipment_booking.show_more') }}
        </div>
      </div>
      <div v-if="futureEvents.length === 0 && pastEvents.length === 0" class="mt-4 text-sn-grey-700">
        {{ i18n.t('repositories.equipment_booking.no_events') }}
      </div>
    </template>
    <Teleport to="body">
      <manageEventModal
        v-if="createEvent"
        :repositoryId="repository.id"
        :repositoryRowId="repositoryRow.id"
        @close="createEvent = false"
        @event:created="createEvent = false; this.reloadEvents()"
      ></manageEventModal>
    </Teleport>
  </div>
</template>

<script>
import axios from '../../packs/custom_axios.js';
import manageEventModal from '../equipment_bookings/manage_modal.vue';

import {
  equipment_booking_events_repository_repository_row_path
} from '../../routes.js';

export default {
  name: 'RepositoryEquipmentBooking',
  props: {
    repositoryRow: Object,
    repository: Object
  },
  components: {
    manageEventModal
  },
  computed: {
    equipmentBookingEventsPath() {
      return equipment_booking_events_repository_repository_row_path(
        this.repository.id,
        this.repositoryRow.id
      );
    }
  },
  data() {
    return {
      createEvent: false,
      futureEvents: [],
      pastEvents: [],
      futurePage: 1,
      pastPage: 1
    };
  },
  created() {
    this.fetchEvents('future', this.futurePage);
    this.fetchEvents('past', this.pastPage);
  },
  methods: {
    reloadEvents() {
      this.futureEvents = [];
      this.pastEvents = [];
      this.futurePage = 1;
      this.pastPage = 1;
      this.fetchEvents('future', this.futurePage);
      this.fetchEvents('past', this.pastPage);
    },
    fetchEvents(direction, page) {
      if (!this.repository || !this.repositoryRow) return;

      axios.get(this.equipmentBookingEventsPath, {
        params: {
          direction,
          page
        }
      })
      .then(response => {
        if (direction === 'future') {
          this.futureEvents = this.futureEvents.concat(response.data.data);
          if (response.data.meta.has_next_page) {
            this.futurePage = this.futurePage + 1;
          } else {
            this.futurePage = null;
          }
        } else {
          this.pastEvents = this.pastEvents.concat(response.data.data);
          if (response.data.meta.has_next_page) {
            this.pastPage = this.pastPage + 1;
          } else {
            this.pastPage = null;
          }
        }
      })
    }
  }
};
</script>
